import Foundation

/// Manages reconnection attempts with exponential backoff strategy
public final class ReconnectionManager: @unchecked Sendable {
    /// Current number of retry attempts (using NSLock for thread safety)
    private var retryCount = 0
    private let lock = NSLock()

    /// Maximum number of retry attempts before giving up
    private let maxRetries: Int

    /// Base delay for exponential backoff (in seconds)
    private let baseDelay: TimeInterval

    /// Maximum delay between retry attempts (in seconds)
    private let maxDelay: TimeInterval

    /// Random jitter factor to prevent thundering herd
    private let jitterFactor: Double

    /// Creates a new reconnection manager with configurable parameters
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts (default: 5)
    ///   - baseDelay: Base delay for exponential backoff in seconds (default: 1.0)
    ///   - maxDelay: Maximum delay between retries in seconds (default: 60.0)
    ///   - jitterFactor: Random jitter factor 0.0-1.0 (default: 0.1)
    public init(
        maxRetries: Int = 5,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        jitterFactor: Double = 0.1
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.jitterFactor = min(max(jitterFactor, 0.0), 1.0)
    }

    /// Calculates the next retry delay using exponential backoff with jitter
    /// - Returns: The delay in seconds before the next retry attempt
    public func nextRetryDelay() -> TimeInterval {
        lock.lock()
        defer { lock.unlock() }

        let exponentialDelay = min(pow(2.0, Double(retryCount)) * baseDelay, maxDelay)
        let jitter = exponentialDelay * jitterFactor * Double.random(in: -1.0...1.0)
        let delay = max(exponentialDelay + jitter, baseDelay)
        retryCount += 1
        return delay
    }

    /// Resets the retry count to zero
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        retryCount = 0
    }

    /// Whether there are retries remaining
    public var hasRetriesLeft: Bool {
        lock.lock()
        defer { lock.unlock() }
        return retryCount < maxRetries
    }

    /// Current retry attempt number
    public var currentRetryCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return retryCount
    }

    /// Maximum retry attempts configured
    public var maximumRetries: Int {
        maxRetries
    }
}

/// Connection state for WebSocket connections
public enum ConnectionState: String, CaseIterable, Sendable {
    /// Not connected to the server
    case disconnected

    /// Currently establishing connection
    case connecting

    /// Successfully connected and ready
    case connected

    /// Connection lost, attempting to reconnect
    case reconnecting

    /// Connection failed after all retry attempts
    case failed

    /// Connection terminated by user
    case terminated

    /// Human-readable description of the state
    public var description: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .reconnecting:
            return "Reconnecting..."
        case .failed:
            return "Connection Failed"
        case .terminated:
            return "Terminated"
        }
    }

    /// Whether the state represents an active connection
    public var isActive: Bool {
        self == .connected
    }

    /// Whether the state represents a transitional state
    public var isTransitioning: Bool {
        self == .connecting || self == .reconnecting
    }

    /// Whether the state represents a terminal state
    public var isTerminal: Bool {
        self == .failed || self == .terminated
    }
}