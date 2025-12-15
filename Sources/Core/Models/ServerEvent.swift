import Foundation
import MetaCodable

@Codable @CodedAt("type") public enum ServerEvent: Sendable {
	public struct RateLimit: Equatable, Hashable, Codable, Sendable {
		/// The name of the rate limit
		public let name: String

		/// The maximum allowed value for the rate limit.
		public let limit: Int

		/// The remaining value before the limit is reached.
		public let remaining: Int

		/// Seconds until the rate limit resets.
		public let resetSeconds: Double
	}

	public struct LogProb: Equatable, Hashable, Codable, Sendable {
		public var bytes: [Int]
		public var logprob: Double
		public var token: String
	}

	/// Returned when an error occurs.
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter error: Details of the error.
	case error(eventId: String, error: ServerError)

	/// Returned when a session is created. Emitted automatically when a new connection is established.
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter session: The session resource.
	@CodedAs("session.created")
	case sessionCreated(eventId: String, session: Session)

	/// Returned when a session is updated.
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter session: The session resource.
	@CodedAs("session.updated")
	case sessionUpdated(eventId: String, session: Session)

	/// Returned when a conversation item is created.
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter item: A single item within a Realtime conversation.
	/// - Parameter previousItemId: The ID of the item that precedes this one, if any.
	@CodedAs("conversation.item.created")
	case conversationItemCreated(eventId: String, item: Item, previousItemId: String?)

	/// Returned when a conversation item is added.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter item: A single item within a Realtime conversation.
	/// - Parameter previousItemId: The ID of the item that precedes this one, if any.
	@CodedAs("conversation.item.added")
	case conversationItemAdded(eventId: String, item: Item, previousItemId: String?)

	/// Returned when a conversation item is finalized.
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter item: A single item within a Realtime conversation.
	/// - Parameter previousItemId: The ID of the item that precedes this one, if any.
	@CodedAs("conversation.item.done")
	case conversationItemDone(eventId: String, item: Item, previousItemId: String?)

	/// Returned when a conversation item is finalized.
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter item: A single item within a Realtime conversation.
	@CodedAs("conversation.item.retrieved")
	case conversationItemRetrieved(eventId: String, item: Item)

	/// This event is the output of audio transcription for user audio written to the user audio buffer.
	///
	/// Transcription begins when the input audio buffer is committed by the client or server (in `serverVad` mode).
	///
	/// Transcription runs asynchronously with Response creation, so this event may come before or after the Response events.
	///
	/// Realtime API models accept audio natively, and thus input transcription is a separate process run on a separate ASR (Automatic Speech Recognition) model.
	///
	/// The transcript may diverge somewhat from the model's interpretation, and should be treated as a rough guide.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the user message item containing the audio.
	/// - Parameter contentIndex: The index of the content part containing the audio.
	/// - Parameter transcript: The transcribed text.
	/// - Parameter logprobs: The log probabilities of the transcription.
	/// - Parameter usage: Usage statistics for the transcription.
	@CodedAs("conversation.item.input_audio_transcription.completed")
	case conversationItemInputAudioTranscriptionCompleted(
		eventId: String,
		itemId: String,
		contentIndex: Int,
		transcript: String,
		logprobs: [LogProb]?,
		usage: Response.Usage
	)

	/// Returned when the text value of an input audio transcription content part is updated.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the item.
	/// - Parameter contentIndex: The index of the content part in the item's content array.
	/// - Parameter transcript: The text delta.
	/// - Parameter logprobs: The log probabilities of the transcription.
	/// - Parameter usage: Usage statistics for the transcription.
	@CodedAs("conversation.item.input_audio_transcription.delta")
	case conversationItemInputAudioTranscriptionDelta(
		eventId: String,
		itemId: String,
		contentIndex: Int,
		delta: String,
		logprobs: [LogProb]?
	)

	/// Returned when an input audio transcription segment is identified for an item.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the item containing the input audio content.
	/// - Parameter contentIndex: The index of the input audio content part within the item.
	/// - Parameter id: The segment identifier.
	/// - Parameter speaker: The detected speaker label for this segment.
	/// - Parameter text: The text for this segment.
	/// - Parameter start: Start time of the segment in seconds.
	/// - Parameter end: End time of the segment in seconds.
	@CodedAs("conversation.item.input_audio_transcription.segment")
	case conversationItemInputAudioTranscriptionSegment(
		eventId: String,
		itemId: String,
		contentIndex: Int,
		id: String,
		speaker: String,
		text: String,
		start: Double,
		end: Double
	)

	/// Returned when input audio transcription is configured, and a transcription request for a user message failed.
	///
	/// These events are separate from other error events so that the client can identify the related Item.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the user message item.
	/// - Parameter contentIndex: The index of the content part containing the audio.
	/// - Parameter error: Details of the transcription error.
	@CodedAs("conversation.item.input_audio_transcription.failed")
	case conversationItemInputAudioTranscriptionFailed(eventId: String, itemId: String, contentIndex: Int, error: ServerError)

	/// Returned when an earlier assistant audio message item is truncated by the client.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the assistant message item that was truncated.
	/// - Parameter contentIndex: The index of the content part that was truncated.
	/// - Parameter audioEndMs: The duration up to which the audio was truncated, in milliseconds.
	@CodedAs("conversation.item.truncated")
	case conversationItemTruncated(eventId: String, itemId: String, contentIndex: Int, audioEndMs: Int)

	/// Returned when an item in the conversation is deleted.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the item that was deleted.
	@CodedAs("conversation.item.deleted")
	case conversationItemDeleted(eventId: String, itemId: String)

	/// Returned when an input audio buffer is committed, either by the client or automatically in server VAD mode.
	///
	/// The `itemId` property is the ID of the user message item that will be created, thus a `conversationItemCreated` event will also be sent to the client.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the user message item that will be created.
	/// - Parameter previousItemId: The ID of the preceding item after which the new item will be inserted.
	@CodedAs("input_audio_buffer.committed")
	case inputAudioBufferCommitted(eventId: String, itemId: String, previousItemId: String?)

	/// Returned when the input audio buffer is cleared by the client with a `inputAudioBufferClear` event.
	///
	/// - Parameter eventId: The unique ID of the server event.
	@CodedAs("input_audio_buffer.cleared")
	case inputAudioBufferCleared(eventId: String)

	/// Sent by the server when in `serverVad` mode to indicate that speech has been detected in the audio buffer.
	///
	/// This can happen any time audio is added to the buffer (unless speech is already detected).
	///
	/// The client may want to use this event to interrupt audio playback or provide visual feedback to the user.
	///
	/// The client should expect to receive a `inputAudioBufferSpeechStopped` event when speech stops.
	///
	/// The `itemId` property is the ID of the user message item that will be created when speech stops and will also be included in the `inputAudioBufferSpeechStopped` event (unless the client manually commits the audio buffer during VAD activation).
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the user message item that will be created when speech stops.
	/// - Parameter audioStartMs: Milliseconds since the session started when speech was detected.
	@CodedAs("input_audio_buffer.speech_started")
	case inputAudioBufferSpeechStarted(eventId: String, itemId: String, audioStartMs: Int)

	/// Returned in `serverVad` mode when the server detects the end of speech in the audio buffer.
	///
	/// The server will also send an conversation.item.created event with the user message item that is created from the audio buffer.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the user message item that will be created.
	/// - Parameter audioEndMs: Milliseconds since the session started when speech stopped.
	@CodedAs("input_audio_buffer.speech_stopped")
	case inputAudioBufferSpeechStopped(eventId: String, itemId: String, audioEndMs: Int)

	/// Returned when the server VAD timeout is triggered for the input audio buffer.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the item associated with this segment.
	/// - Parameter audioStartMs: Millisecond offset where speech started within the buffered audio.
	/// - Parameter audioEndMs: Millisecond offset where speech ended within the buffered audio.
	@CodedAs("input_audio_buffer.timeout_triggered")
	case inputAudioBufferTimeoutTriggered(eventId: String, itemId: String, audioStartMs: Int, audioEndMs: Int)

	/// Returned when the output audio buffer starts playing audio.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response to which the output audio belongs.
	@CodedAs("output_audio_buffer.started")
	case outputAudioBufferStarted(eventId: String, responseId: String)

	/// Returned when the output audio buffer stops playing audio.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response to which the output audio belongs.
	@CodedAs("output_audio_buffer.stopped")
	case outputAudioBufferStopped(eventId: String, responseId: String)

	/// Returned when the output audio buffer is cleared.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response to which the output audio belongs.
	@CodedAs("output_audio_buffer.cleared")
	case outputAudioBufferCleared(eventId: String, responseId: String)

	/// Returned when a new Response is created.
	///
	/// The first event of response creation, where the response is in an initial state of `inProgress`.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter response: The response resource.
	@CodedAs("response.created")
	case responseCreated(eventId: String, response: Response)

	/// Returned when a Response is done streaming. Always emitted, no matter the final state.
	///
	/// The Response object included in the `responseDone` event will include all output Items in the Response but will omit the raw audio data.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter response: The response resource.
	@CodedAs("response.done")
	case responseDone(eventId: String, response: Response)

	/// Returned when a new Item is created during response generation.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response to which the item belongs.
	/// - Parameter outputIndex: The index of the output item in the Response.
	/// - Parameter item: A single item within a Realtime conversation.
	@CodedAs("response.output_item.added")
	case responseOutputItemAdded(eventId: String, responseId: String, outputIndex: Int, item: Item)

	/// Returned when an Item is done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response to which the item belongs.
	/// - Parameter outputIndex: The index of the output item in the Response.
	/// - Parameter item: A single item within a Realtime conversation.
	@CodedAs("response.output_item.done")
	case responseOutputItemDone(eventId: String, responseId: String, outputIndex: Int, item: Item)

	/// Returned when a new content part is added to an assistant message item during response generation.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response.
	/// - Parameter itemId: The ID of the item to which the content part was added.
	/// - Parameter outputIndex: The index of the output item in the Response.
	/// - Parameter contentIndex: The index of the content part in the item's content array.
	/// - Parameter part: The content part that was added.
	@CodedAs("response.content_part.added")
	case responseContentPartAdded(
		eventId: String,
		responseId: String,
		itemId: String,
		outputIndex: Int,
		contentIndex: Int,
		part: Item.ContentPart
	)

	/// Returned when a content part is done streaming in an assistant message item. Also emitted when a Response is interrupted, incomplete, or cancelled.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response.
	/// - Parameter itemId: The ID of the item.
	/// - Parameter outputIndex: The index of the output item in the Response.
	/// - Parameter contentIndex: The index of the content part in the item's content array.
	/// - Parameter part: The content part that is done.
	@CodedAs("response.content_part.done")
	case responseContentPartDone(
		eventId: String,
		responseId: String,
		itemId: String,
		outputIndex: Int,
		contentIndex: Int,
		part: Item.ContentPart
	)

	/// Returned when the text value of an `outputText` content part is updated.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response.
	/// - Parameter itemId: The ID of the item.
	/// - Parameter outputIndex: The index of the output item in the Response.
	/// - Parameter contentIndex: The index of the content part in the item's content array.
	/// - Parameter delta: The text delta.
	@CodedAs("response.text.delta")
	case responseTextDelta(
		eventId: String,
		responseId: String,
		itemId: String,
		outputIndex: Int,
		contentIndex: Int,
		delta: String
	)

	/// Returned when the text value of a "text" content part is done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response.
	/// - Parameter itemId: The ID of the item.
	/// - Parameter outputIndex: The index of the output item in the Response.
	/// - Parameter contentIndex: The index of the content part in the item's content array.
	/// - Parameter text: The final text content.
	@CodedAs("response.text.done")
	case responseTextDone(
		eventId: String,
		responseId: String,
		itemId: String,
		outputIndex: Int,
		contentIndex: Int,
		text: String
	)

	/// Returned when the model-generated transcription of audio output is updated.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response.
	/// - Parameter itemId: The ID of the item.
	/// - Parameter outputIndex: The index of the output item in the Response.
	/// - Parameter contentIndex: The index of the content part in the item's content array.
	/// - Parameter delta: The transcript delta.
	@CodedAs("response.output_audio_transcript.delta")
	case responseAudioTranscriptDelta(
		eventId: String,
		responseId: String,
		itemId: String,
		outputIndex: Int,
		contentIndex: Int,
		delta: String
	)

	/// Returned when the model-generated transcription of audio output is done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response.
	/// - Parameter itemId: The ID of the item.
	/// - Parameter outputIndex: The index of the output item in the Response.
	/// - Parameter contentIndex: The index of the content part in the item's content array.
	/// - Parameter transcript: The final transcript of the audio.
	@CodedAs("response.output_audio_transcript.done")
	case responseAudioTranscriptDone(
		eventId: String,
		responseId: String,
		itemId: String,
		outputIndex: Int,
		contentIndex: Int,
		transcript: String
	)

	/// Returned when the model-generated audio is updated.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response.
	/// - Parameter itemId: The ID of the item.
	/// - Parameter outputIndex: The index of the output item in the Response.
	/// - Parameter contentIndex: The index of the content part in the item's content array.
	/// - Parameter delta: Base64-encoded audio data delta.
	@CodedAs("response.output_audio.delta")
	case responseOutputAudioDelta(
		eventId: String,
		responseId: String,
		itemId: String,
		outputIndex: Int,
		contentIndex: Int,
		delta: AudioData
	)

	/// Returned when the model-generated audio is done. Also emitted when a Response is interrupted, incomplete, or cancelled.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response.
	/// - Parameter itemId: The ID of the item.
	/// - Parameter outputIndex: The index of the output item in the Response.
	/// - Parameter contentIndex: The index of the content part in the item's content array.
	@CodedAs("response.output_audio.done")
	case responseOutputAudioDone(
		eventId: String,
		responseId: String,
		itemId: String,
		outputIndex: Int,
		contentIndex: Int
	)

	/// Returned when the model-generated function call arguments are updated.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response.
	/// - Parameter itemId: The ID of the function call item.
	/// - Parameter outputIndex: The index of the output item in the Response.
	/// - Parameter callId: The ID of the function call.
	/// - Parameter delta: The arguments delta as a JSON string.
	@CodedAs("response.function_call_arguments.delta")
	case responseFunctionCallArgumentsDelta(
		eventId: String,
		responseId: String,
		itemId: String,
		outputIndex: Int,
		callId: String,
		delta: String
	)

	/// Returned when the model-generated function call arguments are done streaming. Also emitted when a Response is interrupted, incomplete, or cancelled.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response.
	/// - Parameter itemId: The ID of the function call item.
	/// - Parameter outputIndex: The index of the output item in the Response.
	/// - Parameter callId: The ID of the function call.
	/// - Parameter arguments: The final arguments as a JSON string.
	@CodedAs("response.function_call_arguments.done")
	case responseFunctionCallArgumentsDone(
		eventId: String,
		responseId: String,
		itemId: String,
		outputIndex: Int,
		callId: String,
		arguments: String
	)

	/// Returned when MCP tool call arguments are updated during response generation.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response.
	/// - Parameter itemId: The ID of the MCP tool call item.
	/// - Parameter outputIndex: The index of the output item in the Response.
	/// - Parameter delta: The JSON-encoded arguments delta.
	/// - Parameter obfuscation: If present, indicates the delta text was obfuscated.
	@CodedAs("response.mcp_call_arguments.delta")
	case responseMCPCallArgumentsDelta(
		eventId: String,
		responseId: String,
		itemId: String,
		outputIndex: Int,
		delta: String,
		obfuscation: String?
	)

	/// Returned when MCP tool call arguments are finalized during response generation.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter responseId: The ID of the Response.
	/// - Parameter itemId: The ID of the MCP tool call item.
	/// - Parameter outputIndex: The index of the output item in the Response.
	/// - Parameter arguments: The final JSON-encoded arguments string.
	@CodedAs("response.mcp_call_arguments.done")
	case responseMCPCallArgumentsDone(
		eventId: String,
		responseId: String,
		itemId: String,
		outputIndex: Int,
		arguments: String
	)

	/// Returned when listing MCP tools is in progress for an item.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the MCP list tools item.
	@CodedAs("mcp_list_tools.in_progress")
	case mcpListToolsInProgress(eventId: String, itemId: String)

	/// Returned when listing MCP tools has completed for an item.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the MCP list tools item.
	@CodedAs("mcp_list_tools.completed")
	case mcpListToolsCompleted(eventId: String, itemId: String)

	/// Returned when listing MCP tools has failed for an item.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the MCP list tools item.
	@CodedAs("mcp_list_tools.failed")
	case mcpListToolsFailed(eventId: String, itemId: String)

	/// Returned when an MCP tool call has started and is in progress.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the MCP tool call item.
	/// - Parameter outputIndex: The index of the output item in the Response.
	@CodedAs("response.mcp_call.in_progress")
	case responseMCPCallInProgress(eventId: String, itemId: String, outputIndex: Int)

	/// Returned when an MCP tool call has completed successfully.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the MCP tool call item.
	/// - Parameter outputIndex: The index of the output item in the Response.
	@CodedAs("response.mcp_call.completed")
	case responseMCPCallCompleted(eventId: String, itemId: String, outputIndex: Int)

	/// Returned when an MCP tool call has failed.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter itemId: The ID of the MCP tool call item.
	/// - Parameter outputIndex: The index of the output item in the Response.
	@CodedAs("response.mcp_call.failed")
	case responseMCPCallFailed(eventId: String, itemId: String, outputIndex: Int)

	/// Emitted after every "response.done" event to indicate the updated rate limits.
	///
	/// - Parameter eventId: The unique ID of the server event.
	/// - Parameter rateLimits: List of rate limit information.
	@CodedAs("rate_limits.updated")
	case rateLimitsUpdated(eventId: String, rateLimits: [RateLimit])
}

extension ServerEvent: Identifiable {
	public var id: String {
		switch self {
			case let .error(id, _): id
			case let .sessionCreated(id, _): id
			case let .sessionUpdated(id, _): id
			case let .conversationItemAdded(id, _, _): id
			case let .conversationItemCreated(id, _, _): id
			case let .conversationItemDone(id, _, _): id
			case let .conversationItemRetrieved(id, _): id
			case let .conversationItemInputAudioTranscriptionCompleted(id, _, _, _, _, _): id
			case let .conversationItemInputAudioTranscriptionDelta(id, _, _, _, _): id
			case let .conversationItemInputAudioTranscriptionSegment(id, _, _, _, _, _, _, _): id
			case let .conversationItemInputAudioTranscriptionFailed(id, _, _, _): id
			case let .conversationItemTruncated(id, _, _, _): id
			case let .conversationItemDeleted(id, _): id
			case let .inputAudioBufferCommitted(id, _, _): id
			case let .inputAudioBufferCleared(id): id
			case let .inputAudioBufferSpeechStarted(id, _, _): id
			case let .inputAudioBufferSpeechStopped(id, _, _): id
			case let .inputAudioBufferTimeoutTriggered(id, _, _, _): id
			case let .outputAudioBufferStarted(id, _): id
			case let .outputAudioBufferStopped(id, _): id
			case let .outputAudioBufferCleared(id, _): id
			case let .responseCreated(id, _): id
			case let .responseDone(id, _): id
			case let .responseOutputItemAdded(id, _, _, _): id
			case let .responseOutputItemDone(id, _, _, _): id
			case let .responseContentPartAdded(id, _, _, _, _, _): id
			case let .responseContentPartDone(id, _, _, _, _, _): id
			case let .responseTextDelta(id, _, _, _, _, _): id
			case let .responseTextDone(id, _, _, _, _, _): id
			case let .responseAudioTranscriptDelta(id, _, _, _, _, _): id
			case let .responseAudioTranscriptDone(id, _, _, _, _, _): id
			case let .responseOutputAudioDelta(id, _, _, _, _, _): id
			case let .responseOutputAudioDone(id, _, _, _, _): id
			case let .responseFunctionCallArgumentsDelta(id, _, _, _, _, _): id
			case let .responseFunctionCallArgumentsDone(id, _, _, _, _, _): id
			case let .responseMCPCallArgumentsDelta(id, _, _, _, _, _): id
			case let .responseMCPCallArgumentsDone(id, _, _, _, _): id
			case let .mcpListToolsInProgress(id, _): id
			case let .mcpListToolsCompleted(id, _): id
			case let .mcpListToolsFailed(id, _): id
			case let .responseMCPCallInProgress(id, _, _): id
			case let .responseMCPCallCompleted(id, _, _): id
			case let .responseMCPCallFailed(id, _, _): id
			case let .rateLimitsUpdated(id, _): id
		}
	}
}
