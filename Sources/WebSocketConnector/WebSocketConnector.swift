import Core
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class WebSocketConnector: NSObject, Connector, Sendable {
	public let events: AsyncThrowingStream<ServerEvent, Error>
	@MainActor public private(set) var status = RealtimeAPI.Status.connecting

	private let task: Task<Void, Never>
	private let webSocket: URLSessionWebSocketTask
	private let stream: AsyncThrowingStream<ServerEvent, Error>.Continuation

	private let encoder: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.keyEncodingStrategy = .convertToSnakeCase
		return encoder
	}()

	init(connectingTo request: URLRequest) {
		let (events, stream) = AsyncThrowingStream.makeStream(of: ServerEvent.self)

		let webSocket = URLSession.shared.webSocketTask(with: request)

		self.events = events
		self.stream = stream
		self.webSocket = webSocket

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
						stream.finish(throwing: RealtimeAPI.Error.invalidMessage)
						continue
					}

					try stream.yield(decoder.decode(ServerEvent.self, from: data))
				} catch {
					stream.finish(throwing: error)
					isActive = false
				}
			}

			webSocket.cancel(with: .goingAway, reason: nil)
		}

		super.init()

		webSocket.delegate = self
		webSocket.resume()
	}

	deinit {
		self.disconnect()
	}

	public static func create(connectingTo request: URLRequest) async throws -> WebSocketConnector {
		return self.init(connectingTo: request)
	}

	public func send(event: ClientEvent) async throws {
		let message = try URLSessionWebSocketTask.Message.string(String(data: encoder.encode(event), encoding: .utf8)!)
		try await webSocket.send(message)
	}

	public func disconnect() {
		webSocket.cancel(with: .goingAway, reason: nil)
		task.cancel()
		stream.finish()
	}
}

extension WebSocketConnector: URLSessionWebSocketDelegate {
	public func urlSession(_: URLSession, webSocketTask _: URLSessionWebSocketTask, didOpenWithProtocol _: String?) {
		Task { @MainActor in
			status = .connected
		}
	}

	public func urlSession(_: URLSession, webSocketTask _: URLSessionWebSocketTask, didCloseWith _: URLSessionWebSocketTask.CloseCode, reason _: Data?) {
		Task { @MainActor in
			status = .disconnected
		}
	}
}
