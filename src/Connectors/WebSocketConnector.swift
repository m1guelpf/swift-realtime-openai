import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class WebSocketConnector: NSObject, Connector, Sendable {
	@MainActor public private(set) var onDisconnect: (@Sendable () -> Void)? = nil
	public let events: AsyncThrowingStream<ServerEvent, Error>

	private let task: URLSessionWebSocketTask
	private let stream: AsyncThrowingStream<ServerEvent, Error>.Continuation

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

	public init(connectingTo request: URLRequest) {
		(events, stream) = AsyncThrowingStream.makeStream(of: ServerEvent.self)
		task = URLSession.shared.webSocketTask(with: request)

		super.init()

		task.delegate = self
		receiveMessage()
		task.resume()
	}

	deinit {
		task.cancel(with: .goingAway, reason: nil)
		stream.finish()
		onDisconnect?()
	}

	public func send(event: ClientEvent) async throws {
		let message = try URLSessionWebSocketTask.Message.string(String(data: encoder.encode(event), encoding: .utf8)!)
		try await task.send(message)
	}

	@MainActor public func onDisconnect(_ action: (@Sendable () -> Void)?) {
		onDisconnect = action
	}

	private func receiveMessage() {
		task.receive { [weak self] result in
			guard let self else { return }

			switch result {
				case let .failure(error):
					self.stream.yield(error: error)
					task.cancel(with: .goingAway, reason: nil)
				case let .success(message):
					switch message {
						case let .string(text):
							self.stream.yield(with: Result { try self.decoder.decode(ServerEvent.self, from: text.data(using: .utf8)!) })

						case .data:
							self.stream.yield(error: RealtimeAPIError.invalidMessage)

						@unknown default:
							self.stream.yield(error: RealtimeAPIError.invalidMessage)
					}
			}

			self.receiveMessage()
		}
	}
}

extension WebSocketConnector: URLSessionWebSocketDelegate {
	public func urlSession(_: URLSession, webSocketTask _: URLSessionWebSocketTask, didCloseWith _: URLSessionWebSocketTask.CloseCode, reason _: Data?) {
		stream.finish()

		Task { @MainActor in
			onDisconnect?()
		}
	}
}
