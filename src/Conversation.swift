import Foundation
@preconcurrency import AVFoundation

public enum ConversationError: Error {
	case sessionNotFound
	case converterInitializationFailed
}

@Observable
public final class Conversation: Sendable {
	private let client: RealtimeAPI
	@MainActor private var cancelTask: (() -> Void)?
	private let errorStream: AsyncStream<ServerError>.Continuation

	private let audioEngine = AVAudioEngine()
	private let playerNode = AVAudioPlayerNode()
	private let apiConverter = UnsafeInteriorMutable<AVAudioConverter>()
	private let userConverter = UnsafeInteriorMutable<AVAudioConverter>()
	private let desiredFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24000, channels: 1, interleaved: false)!

	public let errors: AsyncStream<ServerError>
	@MainActor public private(set) var id: String?
	@MainActor public private(set) var session: Session?
	@MainActor public private(set) var entries: [Item] = []
	@MainActor public private(set) var connected: Bool = false
	@MainActor public private(set) var isListening: Bool = false
	@MainActor public private(set) var handlingVoice: Bool = false

	public var isPlaying: Bool {
		playerNode.isPlaying
	}

	private init(client: RealtimeAPI) {
		self.client = client
		(errors, errorStream) = AsyncStream.makeStream(of: ServerError.self)

		let task = Task.detached { [weak self] in
			guard let self else { return }

			for try await event in client.events {
				await self.handleEvent(event)
			}

			await MainActor.run {
				self.connected = false
			}
		}

		Task { @MainActor in
			self.cancelTask = task.cancel

			client.onDisconnect = { [weak self] in
				guard let self else { return }

				Task { @MainActor in
					self.connected = false
				}
			}
		}
	}

	deinit {
		errorStream.finish()

		DispatchQueue.main.asyncAndWait {
			cancelTask?()
			stopHandlingVoice()
		}
	}

	public convenience init(authToken token: String, model: String = "gpt-4o-realtime-preview") {
		self.init(client: RealtimeAPI(authToken: token, model: model))
	}

	public convenience init(connectingTo request: URLRequest) {
		self.init(client: RealtimeAPI(connectingTo: request))
	}

	/// Wait for the connection to be established
	@MainActor public func waitForConnection() async {
		while true {
			if connected {
				return
			}

			try? await Task.sleep(for: .milliseconds(500))
		}
	}

	/// Execute a block of code when the connection is established
	@MainActor public func whenConnected<E>(_ callback: @Sendable () async throws(E) -> Void) async throws(E) {
		await waitForConnection()
		try await callback()
	}

	/// Make changes to the current session
	/// Note that this will fail if the session hasn't started yet. Use `whenConnected` to ensure the session is ready.
	public func updateSession(withChanges callback: (inout Session) -> Void) async throws {
		guard var session = await session else {
			throw ConversationError.sessionNotFound
		}

		callback(&session)

		try await setSession(session)
	}

	/// Set the configuration of the current session
	public func setSession(_ session: Session) async throws {
		// update endpoint errors if we include the session id
		var session = session
		session.id = nil

		try await client.send(event: .updateSession(session))
	}

	/// Send a client event to the server
	public func send(event: ClientEvent) async throws {
		try await client.send(event: event)
	}

	/// Append audio bytes to the conversation.
	/// Commit the audio to trigger a model response when server turn detection is disabled.
	public func send(audioDelta audio: Data, commit: Bool = false) async throws {
		try await send(event: .appendInputAudioBuffer(encoding: audio))
		if commit { try await send(event: .commitInputAudioBuffer()) }
	}

	/// Send a text message and wait for a response
	public func send(from role: Item.ItemRole, text: String, response: Response.Config? = nil) async throws {
		try await send(event: .createConversationItem(Item(message: Item.Message(id: String(randomLength: 32), from: role, content: [.input_text(text)]))))
		try await send(event: .createResponse(response))
	}

	/// Send the response of a function call
	public func send(result output: Item.FunctionCallOutput) async throws {
		try await send(event: .createConversationItem(Item(with: output)))
	}
}

/// Listening/Speaking public API
public extension Conversation {
	@MainActor func toggleListening() throws {
		isListening ? stopListening() : try startListening()
	}

	@MainActor func startListening() throws {
		guard !isListening else { return }
		if !handlingVoice { try startHandlingVoice() }

		Task.detached {
			self.audioEngine.inputNode.installTap(onBus: 0, bufferSize: 4096, format: self.audioEngine.inputNode.outputFormat(forBus: 0)) { [weak self] buffer, _ in
				self?.processAudioBufferFromUser(buffer: buffer)
			}
		}

		isListening = true
	}

	@MainActor func stopListening() {
		guard isListening else { return }

		audioEngine.inputNode.removeTap(onBus: 0)
		isListening = false
	}

	@MainActor func startHandlingVoice() throws {
		guard !handlingVoice else { return }

		guard let converter = AVAudioConverter(from: audioEngine.inputNode.outputFormat(forBus: 0), to: desiredFormat) else {
			throw ConversationError.converterInitializationFailed
		}
		userConverter.set(converter)

		let audioSession = AVAudioSession.sharedInstance()
		try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
		try audioSession.setActive(true)

		audioEngine.attach(playerNode)
		audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: converter.inputFormat)
		try audioEngine.inputNode.setVoiceProcessingEnabled(true)

		audioEngine.prepare()
		do {
			try audioEngine.start()
			handlingVoice = true
		} catch {
			print("Failed to enable audio engine: \(error)")
			audioEngine.disconnectNodeInput(playerNode)
			audioEngine.disconnectNodeOutput(playerNode)

			throw error
		}
	}

	@MainActor func stopHandlingVoice() {
		guard handlingVoice else { return }

		audioEngine.inputNode.removeTap(onBus: 0)
		audioEngine.stop()
		audioEngine.disconnectNodeInput(playerNode)
		audioEngine.disconnectNodeOutput(playerNode)

		isListening = false
		handlingVoice = false
	}
}

/// Event handling private API
private extension Conversation {
	@MainActor func handleEvent(_ event: ServerEvent) {
		switch event {
			case let .error(event):
				errorStream.yield(event.error)
			case let .sessionCreated(event):
				connected = true
				session = event.session
			case let .sessionUpdated(event):
				session = event.session
			case let .conversationCreated(event):
				id = event.conversation.id
			case let .conversationItemCreated(event):
				entries.append(event.item)
			case let .conversationItemInputAudioTranscriptionCompleted(event):
				updateEvent(id: event.itemId) { message in
					guard case let .input_audio(audio) = message.content[event.contentIndex] else { return }

					message.content[event.contentIndex] = .input_audio(.init(audio: audio.audio, transcript: event.transcript))
				}
			case let .conversationItemInputAudioTranscriptionFailed(event):
				errorStream.yield(event.error)
			case let .conversationItemDeleted(event):
				entries.removeAll { $0.id == event.itemId }
			case let .responseContentPartAdded(event):
				updateEvent(id: event.itemId) { message in
					message.content.insert(.init(from: event.part), at: event.contentIndex)
				}
			case let .responseContentPartDone(event):
				updateEvent(id: event.itemId) { message in
					message.content[event.contentIndex] = .init(from: event.part)
				}
			case let .responseTextDelta(event):
				updateEvent(id: event.itemId) { message in
					guard case let .text(text) = message.content[event.contentIndex] else { return }

					message.content[event.contentIndex] = .text(text + event.delta)
				}
			case let .responseTextDone(event):
				updateEvent(id: event.itemId) { message in
					message.content[event.contentIndex] = .text(event.text)
				}
			case let .responseAudioTranscriptDelta(event):
				updateEvent(id: event.itemId) { message in
					guard case let .audio(audio) = message.content[event.contentIndex] else { return }

					message.content[event.contentIndex] = .audio(.init(audio: audio.audio, transcript: (audio.transcript ?? "") + event.delta))
				}
			case let .responseAudioTranscriptDone(event):
				updateEvent(id: event.itemId) { message in
					guard case let .audio(audio) = message.content[event.contentIndex] else { return }

					message.content[event.contentIndex] = .audio(.init(audio: audio.audio, transcript: event.transcript))
				}
			case let .responseAudioDelta(event):
				updateEvent(id: event.itemId) { message in
					guard case let .audio(audio) = message.content[event.contentIndex] else { return }

					message.content[event.contentIndex] = .audio(.init(audio: audio.audio + event.delta, transcript: audio.transcript))
				}
			case let .responseAudioDone(event):
				updateEvent(id: event.itemId) { message in
					guard handlingVoice, case let .audio(audio) = message.content[event.contentIndex] else { return }

					playCompletedAudio(audio.audio)
				}
			case let .responseFunctionCallArgumentsDelta(event):
				updateEvent(id: event.itemId) { functionCall in
					functionCall.arguments.append(event.delta)
				}
			case let .responseFunctionCallArgumentsDone(event):
				updateEvent(id: event.itemId) { functionCall in
					functionCall.arguments = event.arguments
				}
			default:
				return
		}
	}

	@MainActor
	func updateEvent(id: String, modifying closure: (inout Item.Message) -> Void) {
		guard let index = entries.firstIndex(where: { $0.id == id }), case var .message(message) = entries[index] else {
			return
		}

		closure(&message)

		entries[index] = .message(message)
	}

	@MainActor
	func updateEvent(id: String, modifying closure: (inout Item.FunctionCall) -> Void) {
		guard let index = entries.firstIndex(where: { $0.id == id }), case var .functionCall(functionCall) = entries[index] else {
			return
		}

		closure(&functionCall)

		entries[index] = .functionCall(functionCall)
	}
}

/// Audio processing private API
private extension Conversation {
	private func playCompletedAudio(_ audio: Data) {
		guard let buffer = AVAudioPCMBuffer.fromData(audio, format: desiredFormat) else {
			print("Failed to create audio buffer.")
			return
		}

		guard let converter = apiConverter.lazy({ AVAudioConverter(from: buffer.format, to: audioEngine.outputNode.outputFormat(forBus: 0)) }) else {
			print("Failed to create audio converter.")
			return
		}

		let outputFrameCapacity = AVAudioFrameCount(ceil(converter.outputFormat.sampleRate / buffer.format.sampleRate) * Double(buffer.frameLength))

		guard let audio = convertBuffer(buffer: buffer, using: apiConverter.get()!, capacity: outputFrameCapacity) else {
			print("Failed to convert buffer.")
			return
		}

		playerNode.scheduleBuffer(audio, at: nil, options: .interrupts)
		playerNode.play()
	}

	private func processAudioBufferFromUser(buffer: AVAudioPCMBuffer) {
		let ratio = desiredFormat.sampleRate / buffer.format.sampleRate

		guard let convertedBuffer = convertBuffer(buffer: buffer, using: userConverter.get()!, capacity: AVAudioFrameCount(Double(buffer.frameLength) * ratio)) else {
			print("Buffer conversion failed.")
			return
		}

		guard let sampleBytes = convertedBuffer.audioBufferList.pointee.mBuffers.mData else { return }
		let audioData = Data(bytes: sampleBytes, count: Int(convertedBuffer.audioBufferList.pointee.mBuffers.mDataByteSize))

		Task {
			try await send(audioDelta: audioData)
		}
	}

	private func convertBuffer(buffer: AVAudioPCMBuffer, using converter: AVAudioConverter, capacity: AVAudioFrameCount) -> AVAudioPCMBuffer? {
		if buffer.format == converter.outputFormat {
			return buffer
		}

		guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: capacity) else {
			print("Failed to create converted audio buffer.")
			return nil
		}

		var error: NSError?
		var allSamplesReceived = false

		let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
			if allSamplesReceived {
				outStatus.pointee = .noDataNow
				return nil
			}

			allSamplesReceived = true
			outStatus.pointee = .haveData
			return buffer
		}

		if status == .error {
			if let error = error {
				print("Error during conversion: \(error.localizedDescription)")
			}
			return nil
		}

		return convertedBuffer
	}
}
