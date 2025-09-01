import Core
@preconcurrency import WebRTC
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class WebRTCConnector: NSObject, Connector, Sendable {
	enum WebRTCError: Error {
		case missingAudioPermission
		case failedToCreateDataChannel
		case failedToCreatePeerConnection
		case badServerResponse(URLResponse)
		case failedToCreateSDPOffer(Swift.Error)
		case failedToSetLocalDescription(Swift.Error)
		case failedToSetRemoteDescription(Swift.Error)
	}

	public let events: AsyncThrowingStream<ServerEvent, Error>
	@MainActor public private(set) var status = RealtimeAPI.Status.disconnected

	public var isMuted: Bool {
		!audioTrack.isEnabled
	}

	private let audioTrack: RTCAudioTrack
	private let dataChannel: RTCDataChannel
	private let connection: RTCPeerConnection

	private let stream: AsyncThrowingStream<ServerEvent, Error>.Continuation

	private static let factory: RTCPeerConnectionFactory = {
		RTCInitializeSSL()

		return RTCPeerConnectionFactory()
	}()

	private let encoder: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.keyEncodingStrategy = .convertToSnakeCase
		return encoder
	}()

	private let decoder: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		return decoder
	}()

	private init(connection: RTCPeerConnection, audioTrack: RTCAudioTrack, dataChannel: RTCDataChannel) {
		self.connection = connection
		self.audioTrack = audioTrack
		self.dataChannel = dataChannel
		(events, stream) = AsyncThrowingStream.makeStream(of: ServerEvent.self)

		super.init()

		connection.delegate = self
		dataChannel.delegate = self
	}

	deinit {
		disconnect()
	}

	package func connect(using request: URLRequest) async throws {
		guard connection.connectionState == .new else { return }
		guard AVAudioApplication.shared.recordPermission == .granted else {
			throw WebRTCError.missingAudioPermission
		}

		try await performHandshake(using: request)
		Self.configureAudioSession()
	}

	public func send(event: ClientEvent) async throws {
		try dataChannel.sendData(RTCDataBuffer(data: encoder.encode(event), isBinary: false))
	}

	public func disconnect() {
		connection.close()
		stream.finish()
		Task { @MainActor in status = .disconnected }
	}

	public func toggleMute() {
		audioTrack.isEnabled.toggle()
	}
}

extension WebRTCConnector {
	public static func create(connectingTo request: URLRequest) async throws -> WebRTCConnector {
		let connector = try create()
		try await connector.connect(using: request)
		return connector
	}

	package static func create() throws -> WebRTCConnector {
		guard let connection = factory.peerConnection(
			with: RTCConfiguration(),
			constraints: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil),
			delegate: nil
		) else { throw WebRTCError.failedToCreatePeerConnection }

		let audioTrack = Self.setupLocalAudio(for: connection)

		guard let dataChannel = connection.dataChannel(forLabel: "oai-events", configuration: RTCDataChannelConfiguration()) else {
			throw WebRTCError.failedToCreateDataChannel
		}

		return self.init(connection: connection, audioTrack: audioTrack, dataChannel: dataChannel)
	}
}

private extension WebRTCConnector {
	static func setupLocalAudio(for connection: RTCPeerConnection) -> RTCAudioTrack {
		let audioSource = factory.audioSource(with: RTCMediaConstraints(
			mandatoryConstraints: [
				"googNoiseSuppression": "true", "googHighpassFilter": "true",
				"googEchoCancellation": "true", "googAutoGainControl": "true",
			],
			optionalConstraints: nil
		))

		return tap(factory.audioTrack(with: audioSource, trackId: "local_audio")) { audioTrack in
			connection.add(audioTrack, streamIds: ["local_stream"])
		}
	}

	static func configureAudioSession() {
		do {
			let audioSession = AVAudioSession.sharedInstance()
			try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker])
			try audioSession.setMode(.videoChat)
			try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
		} catch {
			print("Failed to configure AVAudioSession: \(error)")
		}
	}

	func performHandshake(using request: URLRequest) async throws {
		let sdp = try await Result { try await connection.offer(for: RTCMediaConstraints(mandatoryConstraints: ["levelControl": "true"], optionalConstraints: nil)) }
			.mapError(WebRTCError.failedToCreateSDPOffer)
			.get()

		do { try await connection.setLocalDescription(sdp) }
		catch { throw WebRTCError.failedToSetLocalDescription(error) }

		let remoteSdp = try await fetchRemoteSDP(using: request, localSdp: connection.localDescription!.sdp)

		do { try await connection.setRemoteDescription(RTCSessionDescription(type: .answer, sdp: remoteSdp)) }
		catch { throw WebRTCError.failedToSetRemoteDescription(error) }
	}

	private func fetchRemoteSDP(using request: URLRequest, localSdp: String) async throws -> String {
		var request = request
		request.httpBody = localSdp.data(using: .utf8)
		request.setValue("application/sdp", forHTTPHeaderField: "Content-Type")

		let (data, response) = try await URLSession.shared.data(for: request)
		guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode), let remoteSdp = String(data: data, encoding: .utf8) else {
			throw WebRTCError.badServerResponse(response)
		}

		return remoteSdp
	}
}

extension WebRTCConnector: RTCPeerConnectionDelegate {
	public func peerConnectionShouldNegotiate(_: RTCPeerConnection) {}
	public func peerConnection(_: RTCPeerConnection, didAdd _: RTCMediaStream) {}
	public func peerConnection(_: RTCPeerConnection, didOpen _: RTCDataChannel) {}
	public func peerConnection(_: RTCPeerConnection, didRemove _: RTCMediaStream) {}
	public func peerConnection(_: RTCPeerConnection, didChange _: RTCSignalingState) {}
	public func peerConnection(_: RTCPeerConnection, didGenerate _: RTCIceCandidate) {}
	public func peerConnection(_: RTCPeerConnection, didRemove _: [RTCIceCandidate]) {}
	public func peerConnection(_: RTCPeerConnection, didChange _: RTCIceGatheringState) {}

	public func peerConnection(_: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
		print("ICE Connection State changed to: \(newState)")
	}
}

extension WebRTCConnector: RTCDataChannelDelegate {
	public func dataChannel(_: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
		stream.yield(with: Result { try self.decoder.decode(ServerEvent.self, from: buffer.data) })
	}

	public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
		Task { @MainActor [state = dataChannel.readyState] in
			switch state {
				case .open: status = .connected
				case .closing, .closed: status = .disconnected
				default: break
			}
		}
	}
}
