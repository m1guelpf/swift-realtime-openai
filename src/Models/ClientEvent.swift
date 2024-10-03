
import Foundation

public enum ClientEvent: Sendable {
	public struct SessionUpdateEvent: Encodable, Sendable {
		/// Optional client-generated ID used to identify this event.
		var event_id: String?
		/// Session configuration to update.
		var session: Session

		private let type = "session.update"
	}

	public struct InputAudioBufferAppendEvent: Encodable, Sendable {
		/// Optional client-generated ID used to identify this event.
		var event_id: String?
		/// Base64-encoded audio bytes.
		var audio: String

		private let type = "input_audio_buffer.append"
	}

	public struct InputAudioBufferCommitEvent: Encodable, Sendable {
		/// Optional client-generated ID used to identify this event.
		var event_id: String?

		private let type = "input_audio_buffer.commit"
	}

	public struct InputAudioBufferClearEvent: Encodable, Sendable {
		/// Optional client-generated ID used to identify this event.
		var event_id: String?

		private let type = "input_audio_buffer.clear"
	}

	public struct ConversationItemCreateEvent: Encodable, Sendable {
		/// Optional client-generated ID used to identify this event.
		var event_id: String?
		/// The ID of the preceding item after which the new item will be inserted.
		var previous_item_id: String?
		/// The item to add to the conversation.
		var item: Item

		private let type = "conversation.item.create"
	}

	public struct ConversationItemTruncateEvent: Encodable, Sendable {
		/// Optional client-generated ID used to identify this event.
		var event_id: String?
		/// The ID of the assistant message item to truncate.
		var item_id: String?
		/// The index of the content part to truncate.
		var content_index: Int
		/// Inclusive duration up to which audio is truncated, in milliseconds.
		var audio_end_ms: Int

		private let type = "conversation.item.truncate"
	}

	public struct ConversationItemDeleteEvent: Encodable, Sendable {
		/// Optional client-generated ID used to identify this event.
		var event_id: String?
		/// The ID of the assistant message item to truncate.
		var item_id: String?
		/// The index of the content part to truncate.
		var content_index: Int
		/// Inclusive duration up to which audio is truncated, in milliseconds.
		var audio_end_ms: Int

		private let type = "conversation.item.delete"
	}

	public struct ResponseCreateEvent: Encodable, Sendable {
		/// Optional client-generated ID used to identify this event.
		var event_id: String?
		/// Configuration for the response.
		var response: Response.Config?

		private let type = "response.create"
	}

	public struct ResponseCancelEvent: Encodable, Sendable {
		/// Optional client-generated ID used to identify this event.
		var event_id: String?

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

extension ClientEvent {
    public static func updateSession(id: String? = nil, _ session: Session) -> Self {
		.updateSession(SessionUpdateEvent(event_id: id, session: session))
	}

	public static func appendInputAudioBuffer(id: String? = nil, encoding audio: Data) -> Self {
		.appendInputAudioBuffer(InputAudioBufferAppendEvent(event_id: id, audio: audio.base64EncodedString()))
	}

	public static func commitInputAudioBuffer(id: String? = nil) -> Self {
		.commitInputAudioBuffer(InputAudioBufferCommitEvent(event_id: id))
	}

	public static func clearInputAudioBuffer(id: String? = nil) -> Self {
		.clearInputAudioBuffer(InputAudioBufferClearEvent(event_id: id))
	}

	public static func createConversationItem(id: String? = nil, previous previousID: String? = nil, _ item: Item) -> Self {
		.createConversationItem(ConversationItemCreateEvent(event_id: id, previous_item_id: previousID, item: item))
	}

	public static func truncateConversationItem(id event_id: String? = nil, for id: String? = nil, at index: Int, at_audio audio_index: Int) -> Self {
		.truncateConversationItem(ConversationItemTruncateEvent(event_id: event_id, item_id: id, content_index: index, audio_end_ms: audio_index))
	}

	public static func deleteConversationItem(id event_id: String? = nil, for id: String? = nil, at index: Int, at_audio audio_index: Int) -> Self {
		.deleteConversationItem(ConversationItemDeleteEvent(event_id: event_id, item_id: id, content_index: index, audio_end_ms: audio_index))
	}

	public static func createResponse(id: String? = nil, _ response: Response.Config? = nil) -> Self {
		.createResponse(ResponseCreateEvent(event_id: id, response: response))
	}

	public static func cancelResponse(id: String? = nil) -> Self {
		.cancelResponse(ResponseCancelEvent(event_id: id))
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
