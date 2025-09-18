import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(Network)
import Network
#endif

public final class WebSocketConnector: Connector, Sendable {
	@MainActor public private(set) var onDisconnect: (@Sendable () -> Void)? = nil
	public let events: AsyncThrowingStream<ServerEvent, Error>

	/// Current connection state
	@MainActor public private(set) var connectionState: ConnectionState = .disconnected

	/// Stream for monitoring connection state changes
	public let stateChanges: AsyncStream<ConnectionState>

	private let task = UnsafeInteriorMutable<Task<Void, Never>?>()
	private let webSocket = UnsafeInteriorMutable<URLSessionWebSocketTask?>()
	private let stream: AsyncThrowingStream<ServerEvent, Error>.Continuation
	private let stateStream: AsyncStream<ConnectionState>.Continuation

	private let originalRequest: URLRequest
	private let reconnectionManager: ReconnectionManager
	private let operationTimeout: TimeInterval
	private let isManuallyDisconnected = UnsafeInteriorMutable<Bool>()

	#if canImport(Network)
	private let networkMonitor = NWPathMonitor()
	private let monitorQueue = DispatchQueue(label: "com.openai.realtime.networkmonitor")
	#endif

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

	/// Creates a new WebSocket connector (protocol requirement)
	public convenience init(connectingTo request: URLRequest) async throws {
		self.init(connectingTo: request, maxRetries: 5, operationTimeout: 30.0)
	}

	/// Creates a new WebSocket connector with enhanced connection management
	/// - Parameters:
	///   - request: URLRequest for the WebSocket connection
	///   - maxRetries: Maximum number of reconnection attempts (default: 5)
	///   - operationTimeout: Timeout for operations in seconds (default: 30)
	public init(
		connectingTo request: URLRequest,
		maxRetries: Int = 5,
		operationTimeout: TimeInterval = 30.0
	) {
		let (events, stream) = AsyncThrowingStream.makeStream(of: ServerEvent.self)
		let (stateChanges, stateStream) = AsyncStream.makeStream(of: ConnectionState.self)

		self.events = events
		self.stream = stream
		self.stateChanges = stateChanges
		self.stateStream = stateStream
		self.originalRequest = request
		self.operationTimeout = operationTimeout
		self.reconnectionManager = ReconnectionManager(
			maxRetries: maxRetries,
			baseDelay: 1.0,
			maxDelay: 60.0,
			jitterFactor: 0.1
		)

		// Initialize state
		isManuallyDisconnected.set(false)

		// Start connection
		Task { @MainActor in
			await self.updateConnectionState(.connecting)
			await self.connect()
		}

		// Setup network monitoring
		#if canImport(Network)
		setupNetworkMonitoring()
		#endif
	}

	/// Establishes the WebSocket connection
	@MainActor
	private func connect() async {
		// Cancel any existing connection
		if let currentTask = task.get() {
			currentTask?.cancel()
		}
		if let currentWebSocket = webSocket.get() {
			currentWebSocket?.cancel(with: .goingAway, reason: Data())
		}

		let webSocketTask = URLSession.shared.webSocketTask(with: originalRequest)
		self.webSocket.set(webSocketTask)
		webSocketTask.resume()

		let timeout = operationTimeout
		let newTask = Task.detached { [weak self, webSocketTask, stream, decoder = self.decoder] in
			var isActive = true

			// Wait for connection establishment with timeout
			let connectionTimeout = Task {
				try await Task.sleep(nanoseconds: UInt64(timeout) * 1_000_000_000)
				return false
			}

			while isActive, webSocketTask.closeCode == .invalid, !Task.isCancelled {
				guard webSocketTask.closeCode == .invalid else {
					await self?.handleDisconnection()
					isActive = false
					break
				}

				do {
					let message = try await webSocketTask.receive()
					connectionTimeout.cancel()

					// Update connection state on first successful receive
					if await self?.connectionState == .connecting {
						await self?.updateConnectionState(.connected)
						self?.reconnectionManager.reset()
					}

					guard case let .string(text) = message, let data = text.data(using: .utf8) else {
						stream.yield(error: RealtimeAPIError.invalidMessage)
						continue
					}

					try stream.yield(decoder.decode(ServerEvent.self, from: data))
				} catch {
					if !Task.isCancelled {
						stream.yield(error: error)
						await self?.handleDisconnection()
					}
					isActive = false
				}
			}

			webSocketTask.cancel(with: .goingAway, reason: Data())
		}
		task.set(newTask)
	}

	/// Handles disconnection and attempts reconnection if appropriate
	@MainActor
	private func handleDisconnection() async {

		guard !(isManuallyDisconnected.get() ?? false) else {
			await updateConnectionState(.disconnected)
			onDisconnect?()
			return
		}

		// Check if we should attempt reconnection
		guard reconnectionManager.hasRetriesLeft else {
			await updateConnectionState(.failed)
			stream.yield(error: ConversationError.reconnectionFailed(attempts: reconnectionManager.maximumRetries))
			onDisconnect?()
			return
		}

		// Attempt reconnection
		await updateConnectionState(.reconnecting)
		let delay = reconnectionManager.nextRetryDelay()

		Task { @MainActor in
			try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

			if !(self.isManuallyDisconnected.get() ?? false) && self.connectionState == .reconnecting {
				await self.connect()
			}
		}
	}

	/// Updates the connection state and notifies observers
	@MainActor
	private func updateConnectionState(_ newState: ConnectionState) async {
		guard connectionState != newState else { return }
		connectionState = newState
		stateStream.yield(newState)
	}


	#if canImport(Network)
	/// Sets up network monitoring to detect connectivity changes
	private func setupNetworkMonitoring() {
		networkMonitor.pathUpdateHandler = { [weak self] path in
			Task { @MainActor [weak self] in
				guard let self = self else { return }

				if path.status == .satisfied && self.connectionState == .failed {
					// Network became available, attempt reconnection
					self.reconnectionManager.reset()
					await self.updateConnectionState(.reconnecting)
					await self.connect()
				} else if path.status == .unsatisfied && self.connectionState == .connected {
					// Network lost
					self.stream.yield(error: ConversationError.networkUnavailable)
				}
			}
		}
		networkMonitor.start(queue: monitorQueue)
	}
	#endif

	deinit {
		isManuallyDisconnected.set(true)
		if let ws = webSocket.get() {
			ws?.cancel(with: .goingAway, reason: Data())
		}
		if let t = task.get() {
			t?.cancel()
		}
		stream.finish()
		stateStream.finish()
		#if canImport(Network)
		networkMonitor.cancel()
		#endif
		onDisconnect?()
	}

	/// Sends an event to the WebSocket with timeout protection
	public func send(event: ClientEvent) async throws {
		guard let webSocketTask = webSocket.get() else {
			throw ConversationError.connectionLost(underlyingError: RealtimeAPIError.invalidMessage)
		}

		// Allow sending in both connecting and connected states since WebSocket is ready
		let currentState = await connectionState
		guard currentState == .connected || currentState == .connecting else {
			throw ConversationError.connectionLost(underlyingError: RealtimeAPIError.invalidMessage)
		}

		let message = try URLSessionWebSocketTask.Message.string(
			String(data: encoder.encode(event), encoding: .utf8)!
		)

		// Send with timeout
		let sendTask = Task {
			try await webSocketTask?.send(message)
		}

		let timeoutTask = Task {
			try await Task.sleep(nanoseconds: UInt64(operationTimeout * 1_000_000_000))
			sendTask.cancel()
			throw ConversationError.timeout(operation: "send", duration: operationTimeout)
		}

		do {
			_ = try await sendTask.value
			timeoutTask.cancel()
		} catch {
			timeoutTask.cancel()
			if error is CancellationError {
				throw ConversationError.timeout(operation: "send", duration: operationTimeout)
			}
			throw error
		}
	}

	/// Manually disconnects the WebSocket connection
	@MainActor
	public func disconnect() async {
		isManuallyDisconnected.set(true)
		await updateConnectionState(.disconnected)
		if let ws = webSocket.get() {
			ws?.cancel(with: .goingAway, reason: Data())
		}
		if let t = task.get() {
			t?.cancel()
		}
		onDisconnect?()
	}

	/// Manually reconnects the WebSocket connection
	@MainActor
	public func reconnect() async {
		isManuallyDisconnected.set(false)
		reconnectionManager.reset()
		await updateConnectionState(.reconnecting)
		await connect()
	}

	@MainActor public func onDisconnect(_ action: (@Sendable () -> Void)?) {
		onDisconnect = action
	}
}
