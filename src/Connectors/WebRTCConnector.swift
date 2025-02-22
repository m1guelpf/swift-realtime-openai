@preconcurrency import WebRTC
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class WebRTCConnector: NSObject, Connector, Sendable {
	enum WebRTCError: Error {
		case failedToCreateDataChannel
		case failedToCreatePeerConnection
		case badServerResponse
	}

	@MainActor public private(set) var onDisconnect: (@Sendable () -> Void)? = nil
	public let events: AsyncThrowingStream<ServerEvent, Error>

	private let connection: RTCPeerConnection
	private let dataChannel: RTCDataChannel

	private let stream: AsyncThrowingStream<ServerEvent, Error>.Continuation

	private static let factory: RTCPeerConnectionFactory = {
		RTCInitializeSSL()

		return RTCPeerConnectionFactory()
	}()

  public func getConnection() -> RTCPeerConnection {
    self.connection
  }
  
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

	public required init(connectingTo request: URLRequest) async throws {
		guard let connection = WebRTCConnector.factory.peerConnection(with: .init(), constraints: .init(mandatoryConstraints: nil, optionalConstraints: nil), delegate: nil) else {
			throw WebRTCError.failedToCreatePeerConnection
		}
		self.connection = connection

    let audioTrackSource = WebRTCConnector.factory.audioSource(with: nil)
    let audioTrack = WebRTCConnector.factory.audioTrack(with: audioTrackSource, trackId: "audio0")
    let mediaStream = WebRTCConnector.factory.mediaStream(withStreamId: "stream0")
    mediaStream.addAudioTrack(audioTrack)
    self.connection.add(audioTrack, streamIds: ["stream0"])
        
    guard let dataChannel = self.connection.dataChannel(forLabel: "oai-events", configuration: RTCDataChannelConfiguration()) else {
      throw WebRTCError.failedToCreateDataChannel
    }
    self.dataChannel = dataChannel

		(events, stream) = AsyncThrowingStream.makeStream(of: ServerEvent.self)

		super.init()

		connection.delegate = self
		dataChannel.delegate = self

		var request = request
    
    let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: [
      "OfferToReceiveAudio": "true",
      "googEchoCancellation": "true",
        "googAutoGainControl": "true",
        "googNoiseSuppression": "true",
        "googHighpassFilter": "true"
    ])
    
    let offer = try await self.connection.offer(for: constraints)
    
		try await self.connection.setLocalDescription(offer)

		request.httpBody = offer.sdp.data(using: .utf8)
    
		let (data, res) = try await URLSession.shared.data(for: request)
		guard (res as? HTTPURLResponse)?.statusCode == 201, let sdp = String(data: data, encoding: .utf8) else {
			throw WebRTCError.badServerResponse
		}

		try await self.connection.setRemoteDescription(RTCSessionDescription(type: .answer, sdp: sdp))
	}

	deinit {
		connection.close()
		stream.finish()
		onDisconnect?()
	}

	public func send(event: ClientEvent) async throws {
		try dataChannel.sendData(RTCDataBuffer(data: encoder.encode(event), isBinary: false))
	}

	@MainActor public func onDisconnect(_ action: (@Sendable () -> Void)?) {
		onDisconnect = action
	}
}

extension WebRTCConnector: RTCPeerConnectionDelegate {
	public func peerConnection(_: RTCPeerConnection, didChange _: RTCSignalingState) {
		print("Connection state changed to \(connection.signalingState)")
	}

	public func peerConnection(_: RTCPeerConnection, didAdd stream: RTCMediaStream) {
		print("Media stream added.")
    if let audioTrack = stream.audioTracks.first {
        print("Audio track received")
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } catch{
        }
    }
	}

	public func peerConnection(_: RTCPeerConnection, didRemove _: RTCMediaStream) {
		print("Media stream removed.")
	}

	public func peerConnectionShouldNegotiate(_: RTCPeerConnection) {
		print("Negotiating connection.")
	}

	public func peerConnection(_: RTCPeerConnection, didChange _: RTCIceConnectionState) {
		print("ICE connection state changed to \(connection.iceConnectionState)")
	}

	public func peerConnection(_: RTCPeerConnection, didChange _: RTCIceGatheringState) {
		print("ICE gathering state changed to \(connection.iceGatheringState)")
	}

	public func peerConnection(_: RTCPeerConnection, didGenerate _: RTCIceCandidate) {
		print("ICE candidate generated.")
	}

	public func peerConnection(_: RTCPeerConnection, didRemove _: [RTCIceCandidate]) {
		print("ICE candidate removed.")
	}

	public func peerConnection(_: RTCPeerConnection, didOpen _: RTCDataChannel) {
		print("Data channel opened.")
	}
}

extension WebRTCConnector: RTCDataChannelDelegate {
	public func dataChannel(_: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
		stream.yield(with: Result { try self.decoder.decode(ServerEvent.self, from: buffer.data) })
	}

	public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
		print("Data channel changed to \(dataChannel.readyState)")
	}
}
