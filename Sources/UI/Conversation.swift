import Core
import Foundation
@preconcurrency import AVFoundation
import WebRTCConnector

public enum ConversationError: Error {
	case sessionNotFound
	case converterInitializationFailed
}

@Observable @MainActor
public final class Conversation: @unchecked Sendable {
	private let client: WebRTCConnector
	private var isInterrupting: Bool = false
	private let errorStream: AsyncStream<ServerError>.Continuation

	private var task: Task<Void, Error>!

	/// A stream of errors that occur during the conversation.
	public let errors: AsyncStream<ServerError>

	/// The unique ID of the conversation.
	public private(set) var id: String?

	/// The current session for this conversation.
	public private(set) var session: Session?

	/// A list of items in the conversation.
	public private(set) var entries: [Item] = []

	public var status: RealtimeAPI.Status {
		client.status
	}

	/// Whether the conversation is currently listening to the user's microphone.
	public private(set) var isListening: Bool = false

	/// Whether the user is currently speaking.
	/// This only works when using the server's voice detection.
	public private(set) var isUserSpeaking: Bool = false

	/// Whether the model is currently speaking.
	public private(set) var isPlaying: Bool = false

	/// A list of messages in the conversation.
	/// Note that this doesn't include function call events. To get a complete list, use `entries`.
	public var messages: [Item.Message] {
		entries.compactMap { switch $0 {
			case let .message(message): return message
			default: return nil
		} }
	}

	public required init() throws {
		client = try WebRTCConnector.create()
		(errors, errorStream) = AsyncStream.makeStream(of: ServerError.self)

		task = Task.detached { [weak self] in
			guard let self else { return }

			do {
				for try await event in self.client.events {
					print("Got event")
					await self.handleEvent(event)

					guard !Task.isCancelled else { break }
				}
			} catch {
				print("Unhandled error in conversation task: \(error)")
			}
		}
	}

	public func connect(using request: URLRequest) async throws {
		try await client.connect(using: request)
	}

	public func connect(ephemeralKey: String, model: Model = .gptRealtime) async throws {
		try await connect(using: .webRTCConnectionRequest(ephemeralKey: ephemeralKey, model: model))
	}

	deinit {
		errorStream.finish()

		Task { @MainActor [weak self] in
			self?.task?.cancel()
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
	public func updateSession(withChanges callback: (inout Session) throws -> Void) async throws {
		guard var session = session else { throw ConversationError.sessionNotFound }

		try callback(&session)

		try await setSession(session)
	}

	/// Set the configuration of the current session
	public func setSession(_ session: Session) async throws {
		// update endpoint errors if we include the session id
		var session = session
		session.id = nil

		try await client.send(event: .updateSession(session))
	}

	/// Send a client event to the server.
	/// > Warning: This function is intended for advanced use cases. Use the other functions to send messages and audio data.
	public func send(event: ClientEvent) async throws {
		try await client.send(event: event)
	}

	/// Manually append audio bytes to the conversation.
	/// Commit the audio to trigger a model response when server turn detection is disabled.
	/// > Note: The `Conversation` class can automatically handle listening to the user's mic and playing back model responses.
	/// > To get started, call the `startListening` function.
	public func send(audioDelta audio: Data, commit: Bool = false) async throws {
		try await send(event: .appendInputAudioBuffer(encoding: audio))
		if commit { try await send(event: .commitInputAudioBuffer()) }
	}

	/// Send a text message and wait for a response.
	/// Optionally, you can provide a response configuration to customize the model's behavior.
	/// > Note: Calling this function will automatically call `interruptSpeech` if the model is currently speaking.
	public func send(from role: Item.ItemRole, text: String, response: Response.Config? = nil) async throws {
		try await send(event: .createConversationItem(Item(message: Item.Message(id: String(randomLength: 32), from: role, content: [.input_text(text)]))))
		try await send(event: .createResponse(response))
	}

	/// Send the response of a function call.
	public func send(result output: Item.FunctionCallOutput) async throws {
		try await send(event: .createConversationItem(Item(with: output)))
	}
}

/// Event handling private API
private extension Conversation {
	func handleEvent(_ event: ServerEvent) {
		switch event {
			case let .error(_, error):
				errorStream.yield(error)
			case let .sessionCreated(_, session):
				self.session = session
			case let .sessionUpdated(_, session):
				self.session = session
			case let .conversationItemCreated(_, item, _):
				entries.append(item)
			case let .conversationItemDeleted(_, itemId):
				entries.removeAll { $0.id == itemId }
			case let .conversationItemInputAudioTranscriptionCompleted(_, itemId, contentIndex, transcript, _, _):
				updateEvent(id: itemId) { message in
					guard case let .input_audio(audio) = message.content[contentIndex] else { return }

					message.content[contentIndex] = .input_audio(.init(audio: audio.audio, transcript: transcript))
				}
			case let .conversationItemInputAudioTranscriptionFailed(_, _, _, error):
				errorStream.yield(error)
			case let .responseContentPartAdded(_, _, itemId, outputIndex, contentIndex, part):
				updateEvent(id: itemId) { message in
					message.content.insert(.init(from: part), at: contentIndex)
				}
			case let .responseContentPartDone(_, _, itemId, outputIndex, contentIndex, part):
				updateEvent(id: itemId) { message in
					message.content[contentIndex] = .init(from: part)
				}
			case let .responseTextDelta(_, _, itemId, outputIndex, contentIndex, delta):
				updateEvent(id: itemId) { message in
					guard case let .text(text) = message.content[contentIndex] else { return }

					message.content[contentIndex] = .text(text + delta)
				}
			case let .responseTextDone(_, _, itemId, outputIndex, contentIndex, text):
				updateEvent(id: itemId) { message in
					message.content[contentIndex] = .text(text)
				}
			case let .responseAudioTranscriptDelta(_, _, itemId, outputIndex, contentIndex, delta):
				updateEvent(id: itemId) { message in
					guard case let .audio(audio) = message.content[contentIndex] else { return }

					message.content[contentIndex] = .audio(.init(audio: audio.audio, transcript: (audio.transcript ?? "") + delta))
				}
			case let .responseAudioTranscriptDone(_, _, itemId, outputIndex, contentIndex, transcript):
				updateEvent(id: itemId) { message in
					guard case let .audio(audio) = message.content[contentIndex] else { return }

					message.content[contentIndex] = .audio(.init(audio: audio.audio, transcript: transcript))
				}
			case let .responseOutputAudioDelta(_, _, itemId, outputIndex, contentIndex, delta):
				updateEvent(id: itemId) { message in
					guard case let .audio(audio) = message.content[contentIndex] else { return }
					message.content[contentIndex] = .audio(.init(audio: audio.audio + delta.data, transcript: audio.transcript))
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
			case let .responseOutputItemDone(_, _, outputIndex, item):
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
