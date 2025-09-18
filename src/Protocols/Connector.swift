import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol Connector: Sendable {
	var events: AsyncThrowingStream<ServerEvent, Error> { get }
	@MainActor var onDisconnect: (@Sendable () -> Void)? { get }

	init(connectingTo request: URLRequest) async throws

	func send(event: ClientEvent) async throws

	@MainActor func onDisconnect(_ action: (@Sendable () -> Void)?)
}

// Extension to provide default implementation for backward compatibility
public extension Connector {
	/// Connection state (optional for backward compatibility)
	@MainActor var connectionState: ConnectionState? {
		return nil
	}

	/// State changes stream (optional for backward compatibility)
	var stateChanges: AsyncStream<ConnectionState>? {
		return nil
	}
}
