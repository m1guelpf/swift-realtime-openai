import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class WebSocketConnector: Connector, Sendable {
	@MainActor public private(set) var onDisconnect: (@Sendable () -> Void)? = nil
	public let events: AsyncThrowingStream<ServerEvent, Error>

	private let task: Task<Void, Never>
	private let webSocket: URLSessionWebSocketTask
	private let stream: AsyncThrowingStream<ServerEvent, Error>.Continuation

	private let encoder: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.keyEncodingStrategy = .convertToSnakeCase
		return encoder
	}()

	public init(connectingTo request: URLRequest) {
		let (events, stream) = AsyncThrowingStream.makeStream(of: ServerEvent.self)

		let webSocket = URLSession.shared.webSocketTask(with: request)
		webSocket.resume()

		task = Task.detached { [webSocket, stream] in
			var isActive = true

			let decoder = JSONDecoder()
			decoder.keyDecodingStrategy = .convertFromSnakeCase

			while isActive, webSocket.closeCode == .invalid, !Task.isCancelled {
				guard webSocket.closeCode == .invalid else {
					stream.finish()
					isActive = false
					break
				}

				do {
					let message = try await webSocket.receive()

					guard case let .string(text) = message, let data = text.data(using: .utf8) else {
						stream.yield(error: RealtimeAPIError.invalidMessage)
						continue
					}

					try stream.yield(decoder.decode(ServerEvent.self, from: data))
				} catch {
					stream.yield(error: error)
					isActive = false
				}
			}

			webSocket.cancel(with: .goingAway, reason: nil)
		}

		self.events = events
		self.stream = stream
		self.webSocket = webSocket
	}

	deinit {
		webSocket.cancel(with: .goingAway, reason: nil)
		task.cancel()
		stream.finish()
		onDisconnect?()
	}

	public func send(event: ClientEvent) async throws {
		let message = try URLSessionWebSocketTask.Message.string(String(data: encoder.encode(event), encoding: .utf8)!)
		try await webSocket.send(message)
	}

	@MainActor public func onDisconnect(_ action: (@Sendable () -> Void)?) {
		onDisconnect = action
	}
}
