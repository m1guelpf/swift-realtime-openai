import Core
import WebRTC
import AVFAudio
import Foundation

public enum ConversationError: Error {
	case sessionNotFound
	case invalidEphemeralKey
	case converterInitializationFailed
}

@MainActor @Observable
public final class Conversation: @unchecked Sendable {
	public typealias SessionUpdateCallback = (inout Session) -> Void

	private let client: WebRTCConnector
	private var task: Task<Void, Error>!
	private let sessionUpdateCallback: SessionUpdateCallback?
	private let errorStream: AsyncStream<ServerError>.Continuation

	/// Whether to print debug information to the console.
	public var debug: Bool

	/// Whether to mute the user's microphone.
	public var muted: Bool = false {
		didSet {
			client.audioTrack.isEnabled = !muted
		}
	}

	/// The unique ID of the conversation.
	public private(set) var id: String?

	/// A stream of errors that occur during the conversation.
	public let errors: AsyncStream<ServerError>

	/// The current session for this conversation.
	public private(set) var session: Session?

	/// A list of items in the conversation.
	public private(set) var entries: [Item] = []

	public var status: RealtimeAPI.Status {
		client.status
	}

	/// Whether the user is currently speaking.
	/// This only works when using the server's voice detection.
	public private(set) var isUserSpeaking: Bool = false

	/// Whether the model is currently speaking.
	public private(set) var isModelSpeaking: Bool = false

	/// A list of messages in the conversation.
	/// Note that this doesn't include function call events. To get a complete list, use `entries`.
	public var messages: [Item.Message] {
		entries.compactMap { switch $0 {
			case let .message(message): return message
			default: return nil
		} }
	}

	public required init(debug: Bool = false, configuring sessionUpdateCallback: SessionUpdateCallback? = nil) {
		self.debug = debug
		client = try! WebRTCConnector.create()
		self.sessionUpdateCallback = sessionUpdateCallback
		(errors, errorStream) = AsyncStream.makeStream(of: ServerError.self)

		task = Task.detached { [weak self] in
			guard let self else { return }

			do {
				for try await event in self.client.events {
					do { try await self.handleEvent(event) }
					catch { print("Unhandled error in event handler: \(error)") }

					guard !Task.isCancelled else { break }
				}
			} catch {
				print("Unhandled error in conversation task: \(error)")
			}
		}
	}

	deinit {
		client.disconnect()
		errorStream.finish()
	}

	public func connect(using request: URLRequest) async throws {
		await AVAudioApplication.requestRecordPermission()

		try await client.connect(using: request)
	}

	public func connect(ephemeralKey: String, model: Model = .gptRealtime) async throws {
		do {
			try await connect(using: .webRTCConnectionRequest(ephemeralKey: ephemeralKey, model: model))
		} catch let error as WebRTCConnector.WebRTCError {
			guard case .invalidEphemeralKey = error else { throw error }
			throw ConversationError.invalidEphemeralKey
		}
	}

	/// Wait for the connection to be established
	public func waitForConnection() async {
		while status != .connected {
			try? await Task.sleep(for: .milliseconds(500))
		}
	}

	/// Execute a block of code when the connection is established
	public func whenConnected<E>(_ callback: @Sendable () async throws(E) -> Void) async throws(E) {
		await waitForConnection()
		try await callback()
	}

	/// Make changes to the current session
	/// Note that this will fail if the session hasn't started yet. Use `whenConnected` to ensure the session is ready.
	public func updateSession(withChanges callback: (inout Session) throws -> Void) throws {
		guard var session else { throw ConversationError.sessionNotFound }

		try callback(&session)

		try setSession(session)
	}

	/// Set the configuration of the current session
	public func setSession(_ session: Session) throws {
		// update endpoint errors if we include the session id
		var session = session
		session.id = nil

		try client.send(event: .updateSession(session))
	}

	/// Send a client event to the server.
	/// > Warning: This function is intended for advanced use cases. Use the other functions to send messages and audio data.
	public func send(event: ClientEvent) throws {
		try client.send(event: event)
	}

	/// Manually append audio bytes to the conversation.
	/// Commit the audio to trigger a model response when server turn detection is disabled.
	/// > Note: The `Conversation` class can automatically handle listening to the user's mic and playing back model responses.
	/// > To get started, call the `startListening` function.
	public func send(audioDelta audio: Data, commit: Bool = false) throws {
		try send(event: .appendInputAudioBuffer(encoding: audio))
		if commit { try send(event: .commitInputAudioBuffer()) }
	}

	/// Send a text message and wait for a response.
	/// Optionally, you can provide a response configuration to customize the model's behavior.
	public func send(from role: Item.Message.Role, text: String, response: Response.Config? = nil) throws {
		try send(event: .createConversationItem(.message(Item.Message(id: String(randomLength: 32), role: role, content: [.inputText(text)]))))
		try send(event: .createResponse(using: response))
	}

	/// Send the response of a function call.
	public func send(result output: Item.FunctionCallOutput) throws {
		try send(event: .createConversationItem(.functionCallOutput(output)))
	}
}

/// Event handling private API
private extension Conversation {
	func handleEvent(_ event: ServerEvent) throws {
		if debug { print(event) }

		switch event {
			case let .error(_, error):
				errorStream.yield(error)
				print("Received error: \(error)")
			case let .sessionCreated(_, session):
				self.session = session
				if let sessionUpdateCallback { try updateSession(withChanges: sessionUpdateCallback) }
			case let .sessionUpdated(_, session):
				self.session = session
			case let .conversationItemCreated(_, item, _):
				entries.append(item)
			case let .conversationItemDeleted(_, itemId):
				entries.removeAll { $0.id == itemId }
			case let .conversationItemInputAudioTranscriptionCompleted(_, itemId, contentIndex, transcript, _, _):
				updateEvent(id: itemId) { message in
					guard case let .inputAudio(audio) = message.content[contentIndex] else { return }

					message.content[contentIndex] = .inputAudio(.init(audio: audio.audio, transcript: transcript))
				}
			case let .conversationItemInputAudioTranscriptionFailed(_, _, _, error):
				errorStream.yield(error)
				print("Received error: \(error)")
			case let .responseCreated(_, response):
				if id == nil {
					id = response.conversationId
				}
			case let .responseContentPartAdded(_, _, itemId, _, contentIndex, part):
				updateEvent(id: itemId) { message in
					message.content.insert(.init(from: part), at: contentIndex)
				}
			case let .responseContentPartDone(_, _, itemId, _, contentIndex, part):
				updateEvent(id: itemId) { message in
					message.content[contentIndex] = .init(from: part)
				}
			case let .responseTextDelta(_, _, itemId, _, contentIndex, delta):
				updateEvent(id: itemId) { message in
					guard case let .text(text) = message.content[contentIndex] else { return }

					message.content[contentIndex] = .text(text + delta)
				}
			case let .responseTextDone(_, _, itemId, _, contentIndex, text):
				updateEvent(id: itemId) { message in
					message.content[contentIndex] = .text(text)
				}
			case let .responseAudioTranscriptDelta(_, _, itemId, _, contentIndex, delta):
				updateEvent(id: itemId) { message in
					guard case let .audio(audio) = message.content[contentIndex] else { return }

					message.content[contentIndex] = .audio(.init(audio: audio.audio, transcript: (audio.transcript ?? "") + delta))
				}
			case let .responseAudioTranscriptDone(_, _, itemId, _, contentIndex, transcript):
				updateEvent(id: itemId) { message in
					guard case let .audio(audio) = message.content[contentIndex] else { return }

					message.content[contentIndex] = .audio(.init(audio: audio.audio, transcript: transcript))
				}
			case let .responseOutputAudioDelta(_, _, itemId, _, contentIndex, delta):
				updateEvent(id: itemId) { message in
					guard case let .audio(audio) = message.content[contentIndex] else { return }
					message.content[contentIndex] = .audio(.init(audio: (audio.audio?.data ?? Data()) + delta.data, transcript: audio.transcript))
				}
			case let .responseFunctionCallArgumentsDelta(_, _, itemId, _, _, delta):
				updateEvent(id: itemId) { functionCall in
					functionCall.arguments.append(delta)
				}
			case let .responseFunctionCallArgumentsDone(_, _, itemId, _, _, arguments):
				updateEvent(id: itemId) { functionCall in
					functionCall.arguments = arguments
				}
			case .inputAudioBufferSpeechStarted:
				isUserSpeaking = true
			case .inputAudioBufferSpeechStopped:
				isUserSpeaking = false
			case .outputAudioBufferStarted:
				isModelSpeaking = true
			case .outputAudioBufferStopped:
				isModelSpeaking = false
			case let .responseOutputItemDone(_, _, _, item):
				updateEvent(id: item.id) { message in
					guard case let .message(newMessage) = item else { return }

					message = newMessage
				}
			default: break
		}
	}

	func updateEvent(id: String, modifying closure: (inout Item.Message) -> Void) {
		guard let index = entries.firstIndex(where: { $0.id == id }), case var .message(message) = entries[index] else {
			return
		}

		closure(&message)

		entries[index] = .message(message)
	}

	func updateEvent(id: String, modifying closure: (inout Item.FunctionCall) -> Void) {
		guard let index = entries.firstIndex(where: { $0.id == id }), case var .functionCall(functionCall) = entries[index] else {
			return
		}

		closure(&functionCall)

		entries[index] = .functionCall(functionCall)
	}
}
