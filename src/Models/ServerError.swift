public struct ServerError: Codable, Sendable {
	/// The type of error (e.g., "invalid_request_error", "server_error").
	let type: String
	/// Error code, if any.
	let code: String?
	/// A human-readable error message.
	let message: String
	/// Parameter related to the error, if any.
	let param: String?
	/// The event_id of the client event that caused the error, if applicable.
	let event_id: String?
}
