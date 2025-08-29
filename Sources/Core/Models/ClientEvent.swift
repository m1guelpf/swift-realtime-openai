import Foundation

public enum ClientEvent: Equatable, Sendable {
	public struct SessionUpdateEvent: Encodable, Equatable, Sendable {
		/// Optional client-generated ID used to identify this event.
		public var eventId: String?
		/// Session configuration to update.
		public var session: Session

		private let type = "session.update"
	}

	public struct InputAudioBufferAppendEvent: Encodable, Equatable, Sendable {
		/// Optional client-generated ID used to identify this event.
		public var eventId: String?
		/// Base64-encoded audio bytes.
		public var audio: String

		private let type = "input_audio_buffer.append"
	}

	public struct InputAudioBufferCommitEvent: Encodable, Equatable, Sendable {
		/// Optional client-generated ID used to identify this event.
		public var eventId: String?

		private let type = "input_audio_buffer.commit"
	}

	public struct InputAudioBufferClearEvent: Encodable, Equatable, Sendable {
		/// Optional client-generated ID used to identify this event.
		public var eventId: String?

		private let type = "input_audio_buffer.clear"
	}

	public struct ConversationItemCreateEvent: Encodable, Equatable, Sendable {
		/// Optional client-generated ID used to identify this event.
		public var eventId: String?
		/// The ID of the preceding item after which the new item will be inserted.
		public var previousItemId: String?
		/// The item to add to the conversation.
		public var item: Item

		private let type = "conversation.item.create"
	}

	public struct ConversationItemTruncateEvent: Encodable, Equatable, Sendable {
		/// Optional client-generated ID used to identify this event.
		public var eventId: String?
		/// The ID of the assistant message item to truncate.
		public var itemId: String?
		/// The index of the content part to truncate.
		public var contentIndex: Int
		/// Inclusive duration up to which audio is truncated, in milliseconds.
		public var audioEndMs: Int

		private let type = "conversation.item.truncate"
	}

	public struct ConversationItemDeleteEvent: Encodable, Equatable, Sendable {
		/// Optional client-generated ID used to identify this event.
		public var eventId: String?
		/// The ID of the assistant message item to truncate.
		public var itemId: String?
		/// The index of the content part to truncate.
		public var contentIndex: Int
		/// Inclusive duration up to which audio is truncated, in milliseconds.
		public var audioEndMs: Int

		private let type = "conversation.item.delete"
	}

	public struct ResponseCreateEvent: Encodable, Equatable, Sendable {
		/// Optional client-generated ID used to identify this event.
		public var eventId: String?
		/// Configuration for the response.
		public var response: Response.Config?

		private let type = "response.create"
	}

	public struct ResponseCancelEvent: Encodable, Equatable, Sendable {
		/// Optional client-generated ID used to identify this event.
		public var eventId: String?

		private let type = "response.cancel"
	}

	/// Send this event to update the session’s default configuration.
	case updateSession(SessionUpdateEvent)
	/// Send this event to append audio bytes to the input audio buffer.
	case appendInputAudioBuffer(InputAudioBufferAppendEvent)
	/// Send this event to commit audio bytes to a user message.
	case commitInputAudioBuffer(InputAudioBufferCommitEvent)
	/// Send this event to clear the audio bytes in the buffer.
	case clearInputAudioBuffer(InputAudioBufferClearEvent)
	/// Send this event when adding an item to the conversation.
	case createConversationItem(ConversationItemCreateEvent)
	/// Send this event when you want to truncate a previous assistant message’s audio.
	case truncateConversationItem(ConversationItemTruncateEvent)
	/// Send this event when you want to remove any item from the conversation history.
	case deleteConversationItem(ConversationItemDeleteEvent)
	/// Send this event to trigger a response generation.
	case createResponse(ResponseCreateEvent)
	/// Send this event to cancel an in-progress response.
	case cancelResponse(ResponseCancelEvent)
}

public extension ClientEvent {
	static func updateSession(id: String? = nil, _ session: Session) -> Self {
		.updateSession(SessionUpdateEvent(eventId: id, session: session))
	}

	static func appendInputAudioBuffer(id: String? = nil, encoding audio: Data) -> Self {
		.appendInputAudioBuffer(InputAudioBufferAppendEvent(eventId: id, audio: audio.base64EncodedString()))
	}

	static func commitInputAudioBuffer(id: String? = nil) -> Self {
		.commitInputAudioBuffer(InputAudioBufferCommitEvent(eventId: id))
	}

	static func clearInputAudioBuffer(id: String? = nil) -> Self {
		.clearInputAudioBuffer(InputAudioBufferClearEvent(eventId: id))
	}

	static func createConversationItem(id: String? = nil, previous previousID: String? = nil, _ item: Item) -> Self {
		.createConversationItem(ConversationItemCreateEvent(eventId: id, previousItemId: previousID, item: item))
	}

	static func truncateConversationItem(id eventId: String? = nil, forItem itemId: String, at index: Int = 0, atAudioMs audioMs: Int) -> Self {
		.truncateConversationItem(ConversationItemTruncateEvent(eventId: eventId, itemId: itemId, contentIndex: index, audioEndMs: audioMs))
	}

	static func deleteConversationItem(id eventId: String? = nil, for id: String? = nil, at index: Int, atAudio audioIndex: Int) -> Self {
		.deleteConversationItem(ConversationItemDeleteEvent(eventId: eventId, itemId: id, contentIndex: index, audioEndMs: audioIndex))
	}

	static func createResponse(id: String? = nil, _ response: Response.Config? = nil) -> Self {
		.createResponse(ResponseCreateEvent(eventId: id, response: response))
	}

	static func cancelResponse(id: String? = nil) -> Self {
		.cancelResponse(ResponseCancelEvent(eventId: id))
	}
}

extension ClientEvent: Encodable {
	private enum CodingKeys: String, CodingKey {
		case type
	}

	public func encode(to encoder: Encoder) throws {
		switch self {
			case let .updateSession(event):
				try event.encode(to: encoder)
			case let .appendInputAudioBuffer(event):
				try event.encode(to: encoder)
			case let .commitInputAudioBuffer(event):
				try event.encode(to: encoder)
			case let .clearInputAudioBuffer(event):
				try event.encode(to: encoder)
			case let .createConversationItem(event):
				try event.encode(to: encoder)
			case let .truncateConversationItem(event):
				try event.encode(to: encoder)
			case let .deleteConversationItem(event):
				try event.encode(to: encoder)
			case let .createResponse(event):
				try event.encode(to: encoder)
			case let .cancelResponse(event):
				try event.encode(to: encoder)
		}
	}
}
