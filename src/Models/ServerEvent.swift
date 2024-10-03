public enum ServerEvent: Sendable {
	public struct ErrorEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// Details of the error.
		let error: ServerError
	}

	public struct SessionEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The session resource.
		let session: Session
	}

	public struct ConversationCreatedEvent: Codable, Sendable {
		public struct Conversation: Codable, Sendable {
			/// The unique ID of the conversation.
			let id: String
		}

		/// The unique ID of the server event.
		let event_id: String
		/// The conversation resource.
		let conversation: Conversation
	}

	public struct InputAudioBufferCommittedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the preceding item after which the new item will be inserted.
		let previous_item_id: String?
		/// The ID of the user message item that will be created.
		let item_id: String
	}

	public struct InputAudioBufferClearedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
	}

	public struct InputAudioBufferSpeechStartedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// Milliseconds since the session started when speech was detected.
		let audio_start_ms: Int
		/// The ID of the user message item that will be created when speech stops.
		let item_id: String
	}

	public struct InputAudioBufferSpeechStoppedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// Milliseconds since the session started when speech stopped.
		let audio_end_ms: Int
		/// The ID of the user message item that will be created.
		let item_id: String
	}

	public struct ConversationItemCreatedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the preceding item.
		let previous_item_id: String?
		/// The item that was created.
		let item: Item
	}

	public struct ConversationItemInputAudioTranscriptionCompletedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the user message item.
		let item_id: String
		/// The index of the content part containing the audio.
		let content_index: Int
		/// The transcribed text.
		let transcription: String
	}

	public struct ConversationItemInputAudioTranscriptionFailedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the user message item.
		let item_id: String
		/// The index of the content part containing the audio.
		let content_index: Int
		/// Details of the transcription error.
		let error: ServerError
	}

	public struct ConversationItemTruncatedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the assistant message item that was truncated.
		let item_id: String
		/// The index of the content part that was truncated.
		let content_index: Int
		/// The duration up to which the audio was truncated, in milliseconds.
		let audio_end_ms: Int
	}

	public struct ConversationItemDeletedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the item that was deleted.
		let item_id: String
	}

	public struct ResponseEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The response resource.
		let response: Response
	}

	public struct ResponseOutputItemAddedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the response to which the item belongs.
		let response_id: String
		/// The index of the output item in the response.
		let output_index: Int
		/// The item that was added.
		let item: Item
	}

	public struct ResponseOutputItemDoneEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the response to which the item belongs.
		let response_id: String
		/// The index of the output item in the response.
		let output_index: Int
		/// The completed item.
		let item: Item
	}

	public struct ResponseContentPartAddedEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the response.
		let response_id: String
		/// The ID of the item to which the content part was added.
		let item_id: String
		/// The index of the output item in the response.
		let output_index: Int
		/// The index of the content part in the item's content array.
		let content_index: Int
		/// The content part that was added.
		let part: Item.ContentPart
	}

	public struct ResponseContentPartDoneEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the response.
		let response_id: String
		/// The ID of the item.
		let item_id: String
		/// The index of the output item in the response.
		let output_index: Int
		/// The index of the content part in the item's content array.
		let content_index: Int
		/// The content part that is done.
		let part: Item.ContentPart
	}

	public struct ResponseTextDeltaEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the response.
		let response_id: String
		/// The ID of the item.
		let item_id: String
		/// The index of the output item in the response.
		let output_index: Int
		/// The index of the content part in the item's content array.
		let content_index: Int
		/// The text delta.
		let delta: String
	}

	public struct ResponseTextDoneEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the response.
		let response_id: String
		/// The ID of the item.
		let item_id: String
		/// The index of the output item in the response.
		let output_index: Int
		/// The index of the content part in the item's content array.
		let content_index: Int
		/// The final text content.
		let text: String
	}

	public struct ResponseAudioTranscriptDeltaEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the response.
		let response_id: String
		/// The ID of the item.
		let item_id: String
		/// The index of the output item in the response.
		let output_index: Int
		/// The index of the content part in the item's content array.
		let content_index: Int
		/// The transcript delta.
		let delta: String
	}

	public struct ResponseAudioTranscriptDoneEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the response.
		let response_id: String
		/// The ID of the item.
		let item_id: String
		/// The index of the output item in the response.
		let output_index: Int
		/// The index of the content part in the item's content array.
		let content_index: Int
		/// The final transcript of the audio.
		let transcript: String
	}

	public struct ResponseAudioDeltaEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the response.
		let response_id: String
		/// The ID of the item.
		let item_id: String
		/// The index of the output item in the response.
		let output_index: Int
		/// The index of the content part in the item's content array.
		let content_index: Int
		/// Base64-encoded audio data delta.
		let delta: String
	}

	public struct ResponseAudioDoneEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the response.
		let response_id: String
		/// The ID of the item.
		let item_id: String
		/// The index of the output item in the response.
		let output_index: Int
		/// The index of the content part in the item's content array.
		let content_index: Int
	}

	public struct ResponseFunctionCallArgumentsDeltaEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the response.
		let response_id: String
		/// The ID of the function call item.
		let item_id: String
		/// The index of the output item in the response.
		let output_index: Int
		/// The ID of the function call.
		let call_id: String
		/// The arguments delta as a JSON string.
		let delta: String
	}

	public struct ResponseFunctionCallArgumentsDoneEvent: Codable, Sendable {
		/// The unique ID of the server event.
		let event_id: String
		/// The ID of the response.
		let response_id: String
		/// The ID of the function call item.
		let item_id: String
		/// The index of the output item in the response.
		let output_index: Int
		/// The ID of the function call.
		let call_id: String
		/// The final arguments as a JSON string.
		let arguments: String
	}

	public struct RateLimitsUpdatedEvent: Codable, Sendable {
		public struct RateLimit: Codable, Sendable {
			/// The name of the rate limit
			let name: String
			/// The maximum allowed value for the rate limit.
			let limit: Int
			/// The remaining value before the limit is reached.
			let remaining: Int
			/// Seconds until the rate limit resets.
			let reset_seconds: Int
		}

		/// The unique ID of the server event.
		let event_id: String
		/// List of rate limit information.
		let rate_limits: [RateLimit]
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
