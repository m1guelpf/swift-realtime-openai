import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct RealtimeAPI: Sendable {
	public enum Error: Swift.Error {
		case invalidMessage
	}

	public enum Status: String, CaseIterable, Equatable, Hashable, Sendable {
		case connected, connecting, disconnected
	}

	public var events: AsyncThrowingStream<ServerEvent, Swift.Error> {
		connector.events
	}

	let connector: any Connector

	/// Connect to the OpenAI Realtime API using the given connector instance.
	public init(connector: any Connector) {
		self.connector = connector
	}

	public func send(event: ClientEvent) async throws {
		try await connector.send(event: event)
	}
}
