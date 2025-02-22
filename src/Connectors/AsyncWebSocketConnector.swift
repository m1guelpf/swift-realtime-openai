import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class AsyncWebSocketConnector: NSObject, Connector, Sendable {
    
    
    @MainActor public private(set) var onDisconnect: (@Sendable () -> Void)? = nil
    public let events: AsyncThrowingStream<ServerEvent, Error>

    private let webSocket: URLSessionWebSocketTask
    private let stream: AsyncThrowingStream<ServerEvent, Error>.Continuation
    private let task: Task<Void, Never>

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
            
            while isActive && webSocket.closeCode == .invalid && !Task.isCancelled {
                guard webSocket.closeCode == .invalid else {
                    NSLog("🕸️ socket closed WebSocketConnector")
                    stream.yield(error: RealtimeAPIError.disconnected(webSocket.closeCode))
                    break
                }
                do {
                    let message = try await webSocket.receive()
                    
                    switch message {
                    case let .string(text):
                        do {
                            guard let data = text.data(using: .utf8) else {
                                stream.yield(error: RealtimeAPIError.invalidMessage)
                                continue
                            }
                            let event = try decoder.decode(ServerEvent.self, from: data)
                            stream.yield(event)
                        } catch {
                            NSLog("🕸️ parse error WebSocketConnector")
                            stream.yield(error: error)
                        }
                    case .data:
                        NSLog("🕸️ invalid type WebSocketConnector")
                        stream.yield(error: RealtimeAPIError.invalidMessage)
                    @unknown default:
                        NSLog("🕸️ unexpected type WebSocketConnector")
                        stream.yield(error: RealtimeAPIError.invalidMessage)
                    }
                } catch {
                    NSLog("🕸️ catch WebSocketConnector")
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
        NSLog("🕸️ deinit WebSocketConnector")
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
