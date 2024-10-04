import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class RealtimeAPI: NSObject, Sendable {
	@MainActor public var onDisconnect: (@Sendable () -> Void)?
	public let events: AsyncThrowingStream<ServerEvent, Error>

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

	private let task: URLSessionWebSocketTask
	private let stream: AsyncThrowingStream<ServerEvent, Error>.Continuation

	public init(connectingTo request: URLRequest) {
		(events, stream) = AsyncThrowingStream.makeStream(of: ServerEvent.self)
		task = URLSession.shared.webSocketTask(with: request)

		super.init()

		task.delegate = self
		receiveMessage()
		task.resume()
	}

	public convenience init(authToken: String, model: String = "gpt-4o-realtime-preview-2024-10-01") {
		var request = URLRequest(url: URL(string: "wss://api.openai.com/v1/realtime")!.appending(queryItems: [
			URLQueryItem(name: "model", value: model),
		]))
		request.addValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")
		request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

		self.init(connectingTo: request)
	}

	deinit {
		task.cancel(with: .goingAway, reason: nil)
		stream.finish()
		onDisconnect?()
	}

	private func receiveMessage() {
		task.receive { [weak self] result in
			guard let self else { return }

			switch result {
				case let .failure(error):
					self.stream.yield(error: error)
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

	public func send(event: ClientEvent) async throws {
		let message = try URLSessionWebSocketTask.Message.string(String(data: encoder.encode(event), encoding: .utf8)!)
		try await task.send(message)
	}
}

extension RealtimeAPI: URLSessionWebSocketDelegate {
	public func urlSession(_: URLSession, webSocketTask _: URLSessionWebSocketTask, didCloseWith _: URLSessionWebSocketTask.CloseCode, reason _: Data?) {
		stream.finish()
		Task { @MainActor in
			onDisconnect?()
		}
	}
}

enum RealtimeAPIError: Error {
	case invalidMessage
}
