import Core
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension RealtimeAPI {
	/// Connect to the OpenAI WebRTC Realtime API with the given request.
	static func webRTC(connectingTo request: URLRequest) async throws -> RealtimeAPI {
		try RealtimeAPI(connector: await WebRTCConnector.create(connectingTo: request))
	}

	/// Connect to the OpenAI WebRTC Realtime API with the given authentication token and model.
	static func webRTC(ephemeralKey: String, model: Model = .gptRealtime) async throws -> RealtimeAPI {
		return try await webRTC(connectingTo: .webRTCConnectionRequest(ephemeralKey: ephemeralKey, model: model))
	}
}
