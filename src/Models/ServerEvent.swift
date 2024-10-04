import Foundation

public enum ServerEvent: Sendable {
	public struct ErrorEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// Details of the error.
		public let error: ServerError
	}

	public struct SessionEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The session resource.
		public let session: Session
	}

	public struct ConversationCreatedEvent: Decodable, Sendable {
		public struct Conversation: Codable, Sendable {
			/// The unique ID of the conversation.
			public let id: String
		}

		/// The unique ID of the server event.
		public let eventId: String
		/// The conversation resource.
		public let conversation: Conversation
	}

	public struct InputAudioBufferCommittedEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the preceding item after which the new item will be inserted.
		public let previousItemId: String?
		/// The ID of the user message item that will be created.
		public let itemId: String
	}

	public struct InputAudioBufferClearedEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
	}

	public struct InputAudioBufferSpeechStartedEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// Milliseconds since the session started when speech was detected.
		public let audioStartMs: Int
		/// The ID of the user message item that will be created when speech stops.
		public let itemId: String
	}

	public struct InputAudioBufferSpeechStoppedEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// Milliseconds since the session started when speech stopped.
		public let audioEndMs: Int
		/// The ID of the user message item that will be created.
		public let itemId: String
	}

	public struct ConversationItemCreatedEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the preceding item.
		public let previousItemId: String?
		/// The item that was created.
		public let item: Item
	}

	public struct ConversationItemInputAudioTranscriptionCompletedEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the user message item.
		public let itemId: String
		/// The index of the content part containing the audio.
		public let contentIndex: Int
		/// The transcribed text.
		public let transcript: String
	}

	public struct ConversationItemInputAudioTranscriptionFailedEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the user message item.
		public let itemId: String
		/// The index of the content part containing the audio.
		public let contentIndex: Int
		/// Details of the transcription error.
		public let error: ServerError
	}

	public struct ConversationItemTruncatedEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the assistant message item that was truncated.
		public let itemId: String
		/// The index of the content part that was truncated.
		public let contentIndex: Int
		/// The duration up to which the audio was truncated, in milliseconds.
		public let audioEndMs: Int
	}

	public struct ConversationItemDeletedEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the item that was deleted.
		public let itemId: String
	}

	public struct ResponseEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The response resource.
		public let response: Response
	}

	public struct ResponseOutputItemAddedEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response to which the item belongs.
		public let responseId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The item that was added.
		public let item: Item
	}

	public struct ResponseOutputItemDoneEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response to which the item belongs.
		public let responseId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The completed item.
		public let item: Item
	}

	public struct ResponseContentPartAddedEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item to which the content part was added.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
		/// The content part that was added.
		public let part: Item.ContentPart
	}

	public struct ResponseContentPartDoneEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
		/// The content part that is done.
		public let part: Item.ContentPart
	}

	public struct ResponseTextDeltaEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
		/// The text delta.
		public let delta: String
	}

	public struct ResponseTextDoneEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
		/// The final text content.
		public let text: String
	}

	public struct ResponseAudioTranscriptDeltaEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
		/// The transcript delta.
		public let delta: String
	}

	public struct ResponseAudioTranscriptDoneEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
		/// The final transcript of the audio.
		public let transcript: String
	}

	public struct ResponseAudioDeltaEvent: Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
		/// Base64-encoded audio data delta.
		public let delta: Data
	}

	public struct ResponseAudioDoneEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The index of the content part in the item's content array.
		public let contentIndex: Int
	}

	public struct ResponseFunctionCallArgumentsDeltaEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the function call item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The ID of the function call.
		public let callId: String
		/// The arguments delta as a JSON string.
		public let delta: String
	}

	public struct ResponseFunctionCallArgumentsDoneEvent: Decodable, Sendable {
		/// The unique ID of the server event.
		public let eventId: String
		/// The ID of the response.
		public let responseId: String
		/// The ID of the function call item.
		public let itemId: String
		/// The index of the output item in the response.
		public let outputIndex: Int
		/// The ID of the function call.
		public let callId: String
		/// The final arguments as a JSON string.
		public let arguments: String
	}

	public struct RateLimitsUpdatedEvent: Decodable, Sendable {
		public struct RateLimit: Codable, Sendable {
			/// The name of the rate limit
			public let name: String
			/// The maximum allowed value for the rate limit.
			public let limit: Int
			/// The remaining value before the limit is reached.
			public let remaining: Int
			/// Seconds until the rate limit resets.
			public let resetSeconds: Double
		}

		/// The unique ID of the server event.
		public let eventId: String
		/// List of rate limit information.
		public let rateLimits: [RateLimit]
	}

	/// Returned when an error occurs.
	case error(ErrorEvent)
	/// Returned when a session is created. Emitted automatically when a new connection is established.
	case sessionCreated(SessionEvent)
	/// Returned when a session is updated.
	case sessionUpdated(SessionEvent)
	/// Returned when a conversation is created. Emitted right after session creation.
	case conversationCreated(ConversationCreatedEvent)
	/// Returned when an input audio buffer is committed, either by the client or automatically in server VAD mode.
	case inputAudioBufferCommitted(InputAudioBufferCommittedEvent)
	/// Returned when the input audio buffer is cleared by the client.
	case inputAudioBufferCleared(InputAudioBufferClearedEvent)
	/// Returned in server turn detection mode when speech is detected.
	case inputAudioBufferSpeechStarted(InputAudioBufferSpeechStartedEvent)
	/// Returned in server turn detection mode when speech stops.
	case inputAudioBufferSpeechStopped(InputAudioBufferSpeechStoppedEvent)
	/// Returned when a conversation item is created.
	case conversationItemCreated(ConversationItemCreatedEvent)
	/// Returned when input audio transcription is enabled and a transcription succeeds.
	case conversationItemInputAudioTranscriptionCompleted(ConversationItemInputAudioTranscriptionCompletedEvent)
	/// Returned when input audio transcription is configured, and a transcription request for a user message failed.
	case conversationItemInputAudioTranscriptionFailed(ConversationItemInputAudioTranscriptionFailedEvent)
	/// Returned when an earlier assistant audio message item is truncated by the client.
	case conversationItemTruncated(ConversationItemTruncatedEvent)
	/// Returned when an item in the conversation is deleted.
	case conversationItemDeleted(ConversationItemDeletedEvent)
	/// Returned when a new Response is created. The first event of response creation, where the response is in an initial state of "in_progress".
	case responseCreated(ResponseEvent)
	/// Returned when a Response is done streaming. Always emitted, no matter the final state.
	case responseDone(ResponseEvent)
	/// Returned when a new Item is created during response generation.
	case responseOutputItemAdded(ResponseOutputItemAddedEvent)
	/// Returned when an Item is done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.
	case responseOutputItemDone(ResponseOutputItemDoneEvent)
	/// Returned when a new content part is added to an assistant message item during response generation.
	case responseContentPartAdded(ResponseContentPartAddedEvent)
	/// Returned when a content part is done streaming in an assistant message item. Also emitted when a Response is interrupted, incomplete, or cancelled.
	case responseContentPartDone(ResponseContentPartDoneEvent)
	/// Returned when the text value of a "text" content part is updated.
	case responseTextDelta(ResponseTextDeltaEvent)
	/// Returned when the text value of a "text" content part is done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.
	case responseTextDone(ResponseTextDoneEvent)
	/// Returned when the model-generated transcription of audio output is updated.
	case responseAudioTranscriptDelta(ResponseAudioTranscriptDeltaEvent)
	/// Returned when the model-generated transcription of audio output is done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.
	case responseAudioTranscriptDone(ResponseAudioTranscriptDoneEvent)
	/// Returned when the model-generated audio is updated.
	case responseAudioDelta(ResponseAudioDeltaEvent)
	/// Returned when the model-generated audio is done. Also emitted when a Response is interrupted, incomplete, or cancelled.
	case responseAudioDone(ResponseAudioDoneEvent)
	/// Returned when the model-generated function call arguments are updated.
	case responseFunctionCallArgumentsDelta(ResponseFunctionCallArgumentsDeltaEvent)
	/// Returned when the model-generated function call arguments are done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.
	case responseFunctionCallArgumentsDone(ResponseFunctionCallArgumentsDoneEvent)
	/// Emitted after every "response.done" event to indicate the updated rate limits.
	case rateLimitsUpdated(RateLimitsUpdatedEvent)
}

extension ServerEvent: Identifiable {
	public var id: String {
		switch self {
			case let .error(event):
				return event.eventId
			case let .sessionCreated(event):
				return event.eventId
			case let .sessionUpdated(event):
				return event.eventId
			case let .conversationCreated(event):
				return event.eventId
			case let .inputAudioBufferCommitted(event):
				return event.eventId
			case let .inputAudioBufferCleared(event):
				return event.eventId
			case let .inputAudioBufferSpeechStarted(event):
				return event.eventId
			case let .inputAudioBufferSpeechStopped(event):
				return event.eventId
			case let .conversationItemCreated(event):
				return event.eventId
			case let .conversationItemInputAudioTranscriptionCompleted(event):
				return event.eventId
			case let .conversationItemInputAudioTranscriptionFailed(event):
				return event.eventId
			case let .conversationItemTruncated(event):
				return event.eventId
			case let .conversationItemDeleted(event):
				return event.eventId
			case let .responseCreated(event):
				return event.eventId
			case let .responseDone(event):
				return event.eventId
			case let .responseOutputItemAdded(event):
				return event.eventId
			case let .responseOutputItemDone(event):
				return event.eventId
			case let .responseContentPartAdded(event):
				return event.eventId
			case let .responseContentPartDone(event):
				return event.eventId
			case let .responseTextDelta(event):
				return event.eventId
			case let .responseTextDone(event):
				return event.eventId
			case let .responseAudioTranscriptDelta(event):
				return event.eventId
			case let .responseAudioTranscriptDone(event):
				return event.eventId
			case let .responseAudioDelta(event):
				return event.eventId
			case let .responseAudioDone(event):
				return event.eventId
			case let .responseFunctionCallArgumentsDelta(event):
				return event.eventId
			case let .responseFunctionCallArgumentsDone(event):
				return event.eventId
			case let .rateLimitsUpdated(event):
				return event.eventId
		}
	}
}

extension ServerEvent: Decodable {
	private enum CodingKeys: String, CodingKey {
		case type
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let eventType = try container.decode(String.self, forKey: .type)

		switch eventType {
			case "error":
				self = try .error(ErrorEvent(from: decoder))
			case "session.created":
				self = try .sessionCreated(SessionEvent(from: decoder))
			case "session.updated":
				self = try .sessionUpdated(SessionEvent(from: decoder))
			case "conversation.created":
				self = try .conversationCreated(ConversationCreatedEvent(from: decoder))
			case "input_audio_buffer.committed":
				self = try .inputAudioBufferCommitted(InputAudioBufferCommittedEvent(from: decoder))
			case "input_audio_buffer.cleared":
				self = try .inputAudioBufferCleared(InputAudioBufferClearedEvent(from: decoder))
			case "input_audio_buffer.speech_started":
				self = try .inputAudioBufferSpeechStarted(InputAudioBufferSpeechStartedEvent(from: decoder))
			case "input_audio_buffer.speech_stopped":
				self = try .inputAudioBufferSpeechStopped(InputAudioBufferSpeechStoppedEvent(from: decoder))
			case "conversation.item.created":
				self = try .conversationItemCreated(ConversationItemCreatedEvent(from: decoder))
			case "conversation.item.input_audio_transcription.completed":
				self = try .conversationItemInputAudioTranscriptionCompleted(ConversationItemInputAudioTranscriptionCompletedEvent(from: decoder))
			case "conversation.item.input_audio_transcription.failed":
				self = try .conversationItemInputAudioTranscriptionFailed(ConversationItemInputAudioTranscriptionFailedEvent(from: decoder))
			case "conversation.item.truncated":
				self = try .conversationItemTruncated(ConversationItemTruncatedEvent(from: decoder))
			case "conversation.item.deleted":
				self = try .conversationItemDeleted(ConversationItemDeletedEvent(from: decoder))
			case "response.created":
				self = try .responseCreated(ResponseEvent(from: decoder))
			case "response.done":
				self = try .responseDone(ResponseEvent(from: decoder))
			case "response.output_item.added":
				self = try .responseOutputItemAdded(ResponseOutputItemAddedEvent(from: decoder))
			case "response.output_item.done":
				self = try .responseOutputItemDone(ResponseOutputItemDoneEvent(from: decoder))
			case "response.content_part.added":
				self = try .responseContentPartAdded(ResponseContentPartAddedEvent(from: decoder))
			case "response.content_part.done":
				self = try .responseContentPartDone(ResponseContentPartDoneEvent(from: decoder))
			case "response.text.delta":
				self = try .responseTextDelta(ResponseTextDeltaEvent(from: decoder))
			case "response.text.done":
				self = try .responseTextDone(ResponseTextDoneEvent(from: decoder))
			case "response.audio_transcript.delta":
				self = try .responseAudioTranscriptDelta(ResponseAudioTranscriptDeltaEvent(from: decoder))
			case "response.audio_transcript.done":
				self = try .responseAudioTranscriptDone(ResponseAudioTranscriptDoneEvent(from: decoder))
			case "response.audio.delta":
				self = try .responseAudioDelta(ResponseAudioDeltaEvent(from: decoder))
			case "response.audio.done":
				self = try .responseAudioDone(ResponseAudioDoneEvent(from: decoder))
			case "response.function_call_arguments.delta":
				self = try .responseFunctionCallArgumentsDelta(ResponseFunctionCallArgumentsDeltaEvent(from: decoder))
			case "response.function_call_arguments.done":
				self = try .responseFunctionCallArgumentsDone(ResponseFunctionCallArgumentsDoneEvent(from: decoder))
			case "rate_limits.updated":
				self = try .rateLimitsUpdated(RateLimitsUpdatedEvent(from: decoder))
			default:
				throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown event type: \(eventType)")
		}
	}
}

extension ServerEvent.ResponseAudioDeltaEvent: Decodable {
	private enum CodingKeys: CodingKey {
		case eventId
		case responseId
		case itemId
		case outputIndex
		case contentIndex
		case delta
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		itemId = try container.decode(String.self, forKey: .itemId)
		eventId = try container.decode(String.self, forKey: .eventId)
		outputIndex = try container.decode(Int.self, forKey: .outputIndex)
		responseId = try container.decode(String.self, forKey: .responseId)
		contentIndex = try container.decode(Int.self, forKey: .contentIndex)

		guard let decodedDelta = try Data(base64Encoded: container.decode(String.self, forKey: .delta)) else {
			throw DecodingError.dataCorruptedError(forKey: .delta, in: container, debugDescription: "Invalid base64-encoded audio data.")
		}
		delta = decodedDelta
	}
}
