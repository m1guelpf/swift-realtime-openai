import Foundation
import MetaCodable

@Codable @CodedAt("type") public enum ClientEvent: Equatable, Hashable, Sendable {
	/// Send this event to update the session’s default configuration.
	///
	/// The client may send this event at any time to update any field, except for voice.
	/// However, note that once a session has been initialized with a particular model, it can’t be changed to another model using session.update.
	///
	/// When the server receives an `updateSession` event, it will respond with a `sessionUpdated` event showing the full, effective configuration.
	/// Only the fields that are present are updated. To clear a field like `instructions`, pass an empty string.
	///
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	/// - Parameter session: Realtime session configuration.
	@CodedAs("session.update")
	case updateSession(eventId: String?, session: Session)

	/// Send this event to append audio bytes to the input audio buffer.
	///
	/// The audio buffer is temporary storage you can write to and later commit.
	///
	/// In Server VAD mode, the audio buffer is used to detect speech and the server will decide when to commit.
	/// When Server VAD is disabled, you must commit the audio buffer manually.
	///
	/// The client may choose how much audio to place in each event up to a maximum of 15 MiB, for example streaming smaller chunks from the client may allow the VAD to be more responsive.
	///
	/// Unlike made other client events, the server will not send a confirmation response to this event.
	///
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	/// - Parameter audio: Audio bytes.
	@CodedAs("input_audio_buffer.append")
	case appendInputAudioBuffer(eventId: String?, audio: AudioData)

	/// Send this event to commit the user input audio buffer, which will create a new user message item in the conversation.
	///
	/// This event will produce an error if the input audio buffer is empty.
	///
	/// When in Server VAD mode, the client does not need to send this event, the server will commit the audio buffer automatically.
	///
	/// Committing the input audio buffer will trigger input audio transcription (if enabled in session configuration), but it will not create a response from the model.
	/// The server will respond with an `inputAudioBufferCommitted` event.
	///
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	@CodedAs("input_audio_buffer.commit")
	case commitInputAudioBuffer(eventId: String?)

	/// Send this event to clear the audio bytes in the buffer.
	///
	/// The server will respond with an `inputAudioBufferCleared` event.
	///
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	@CodedAs("input_audio_buffer.clear")
	case clearInputAudioBuffer(eventId: String?)

	/// Add a new Item to the Conversation's context, including messages, function calls, and function call responses.
	///
	/// This event can be used both to populate a "history" of the conversation and to add new items mid-stream, but has the current limitation that it cannot populate assistant audio messages.
	///
	/// If successful, the server will respond with a `conversationItemCreated` event, otherwise an error event will be sent.
	///
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	/// - Parameter previousItemId: The ID of the preceding item after which the new item will be inserted. If not set, the new item will be appended to the end of the conversation.
	/// - Parameter item: A single item within a Realtime conversation.
	@CodedAs("conversation.item.create")
	case createConversationItem(eventId: String?, previousItemId: String?, item: Item)

	/// Send this event when you want to retrieve the server's representation of a specific item in the conversation history.
	///
	/// This is useful, for example, to inspect user audio after noise cancellation and VAD.
	///
	/// The server will respond with a `conversationItemRetrieved` event, unless the item does not exist in the conversation history, in which case the server will respond with an error.
	///
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	/// - Parameter itemId: The ID of the item to retrieve.
	@CodedAs("conversation.item.retrieve")
	case retrieveConversationItem(eventId: String?, itemId: String)

	/// Send this event to truncate a previous assistant message’s audio.
	///
	/// The server will produce audio faster than realtime, so this event is useful when the user interrupts to truncate audio that has already been sent to the client but not yet played.
	///
	/// This will synchronize the server's understanding of the audio with the client's playback.
	///
	/// Truncating audio will delete the server-side text transcript to ensure there is not text in the context that hasn't been heard by the user.
	///
	/// If successful, the server will respond with a `conversationItemTruncated` event.
	///
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	/// - Parameter itemId: The ID of the assistant message item to truncate. Only assistant message items can be truncated.
	/// - Parameter contentIndex: The index of the content part to truncate.
	/// - Parameter audioEndMs: Inclusive duration up to which audio is truncated, in milliseconds.
	@CodedAs("conversation.item.truncate")
	case truncateConversationItem(eventId: String?, itemId: String?, contentIndex: Int, audioEndMs: Int)

	/// Send this event when you want to remove any item from the conversation history.
	///
	/// The server will respond with a `conversationItemDeleted` event, unless the item does not exist in the conversation history, in which case the server will respond with an error.
	///
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	/// - Parameter itemId: The ID of the item to delete.
	@CodedAs("conversation.item.delete")
	case deleteConversationItem(eventId: String?, itemId: String?)

	/// This event instructs the server to create a Response, which means triggering model inference.
	///
	/// When in Server VAD mode, the server will create Responses automatically.
	///
	/// A Response will include at least one Item, and may have two, in which case the second will be a function call.
	/// These Items will be appended to the conversation history.
	///
	/// The server will respond with a `responseCreated` event, events for created Items and content, and finally a `responseDone` event to indicate the Response is complete.
	///
	/// The `createResponse` event includes inference configuration like `instructions`, and `temperature`.
	/// These fields will override the Session's configuration for this Response only.
	///
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	/// - Parameter response: Configuration for the response.
	@CodedAs("response.create")
	case createResponse(eventId: String?, response: Response.Config?)

	/// Send this event to cancel an in-progress response.
	///
	/// The server will respond with a `responseDone` event with a status of `cancelled`.
	/// If there is no response to cancel, the server will respond with an error.
	///
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	/// - Parameter responseId: A specific response ID to cancel - if not provided, will cancel an in-progress response in the default conversation.
	@CodedAs("response.cancel")
	case cancelResponse(eventId: String?, responseId: String?)

	/// WebRTC Only: Emit to cut off the current audio response.
	///
	/// This will trigger the server to stop generating audio and emit a `outputAudioBufferCleared` event.
	///
	/// This event should be preceded by a `cancelResponse` client event to stop the generation of the current response. [Learn more](https://platform.openai.com/docs/guides/realtime-conversations#client-and-server-events-for-audio-in-webrtc).
	@CodedAs("output_audio_buffer.clear")
	case outputAudioBufferClear(eventId: String?)
}

public extension ClientEvent {
	/// Send this event to update the session’s default configuration.
	///
	/// The client may send this event at any time to update any field, except for voice.
	/// However, note that once a session has been initialized with a particular model, it can’t be changed to another model using session.update.
	///
	/// When the server receives an `updateSession` event, it will respond with a `sessionUpdated` event showing the full, effective configuration.
	/// Only the fields that are present are updated. To clear a field like `instructions`, pass an empty string.
	///
	/// - Parameter session: Realtime session configuration.
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	static func updateSession(_ session: Session, withEventId eventId: String? = nil) -> ClientEvent {
		.updateSession(eventId: eventId, session: session)
	}

	/// Send this event to append audio bytes to the input audio buffer.
	///
	/// The audio buffer is temporary storage you can write to and later commit.
	///
	/// In Server VAD mode, the audio buffer is used to detect speech and the server will decide when to commit.
	/// When Server VAD is disabled, you must commit the audio buffer manually.
	///
	/// The client may choose how much audio to place in each event up to a maximum of 15 MiB, for example streaming smaller chunks from the client may allow the VAD to be more responsive.
	///
	/// Unlike made other client events, the server will not send a confirmation response to this event.
	///
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	/// - Parameter audio: Audio bytes.
	static func appendInputAudioBuffer(encoding audio: Data, withEventId eventId: String? = nil) -> ClientEvent {
		.appendInputAudioBuffer(eventId: eventId, audio: AudioData(data: audio))
	}

	/// Send this event to commit the user input audio buffer, which will create a new user message item in the conversation.
	///
	/// This event will produce an error if the input audio buffer is empty.
	///
	/// When in Server VAD mode, the client does not need to send this event, the server will commit the audio buffer automatically.
	///
	/// Committing the input audio buffer will trigger input audio transcription (if enabled in session configuration), but it will not create a response from the model.
	/// The server will respond with an `inputAudioBufferCommitted` event.
	///
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	static func commitInputAudioBuffer(withEventId eventId: String? = nil) -> ClientEvent {
		.commitInputAudioBuffer(eventId: eventId)
	}

	/// Send this event to clear the audio bytes in the buffer.
	///
	/// The server will respond with an `inputAudioBufferCleared` event.
	///
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	static func clearInputAudioBuffer(withEventId eventId: String? = nil) -> ClientEvent {
		.clearInputAudioBuffer(eventId: eventId)
	}

	/// Add a new Item to the Conversation's context, including messages, function calls, and function call responses.
	///
	/// This event can be used both to populate a "history" of the conversation and to add new items mid-stream, but has the current limitation that it cannot populate assistant audio messages.
	///
	/// If successful, the server will respond with a `conversationItemCreated` event, otherwise an error event will be sent.
	///
	/// - Parameter previousItemId: The ID of the preceding item after which the new item will be inserted. If not set, the new item will be appended to the end of the conversation.
	/// - Parameter item: A single item within a Realtime conversation.
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	static func createConversationItem(after previousItemId: String? = nil, _ item: Item, withEventId eventId: String? = nil) -> ClientEvent {
		.createConversationItem(eventId: eventId, previousItemId: previousItemId, item: item)
	}

	/// Send this event when you want to retrieve the server's representation of a specific item in the conversation history.
	///
	/// This is useful, for example, to inspect user audio after noise cancellation and VAD.
	///
	/// The server will respond with a `conversationItemRetrieved` event, unless the item does not exist in the conversation history, in which case the server will respond with an error.
	///
	/// - Parameter itemId: The ID of the item to retrieve.
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	static func retrieveConversationItem(by itemId: String, withEventId eventId: String? = nil) -> ClientEvent {
		.retrieveConversationItem(eventId: eventId, itemId: itemId)
	}

	/// Send this event to truncate a previous assistant message’s audio.
	///
	/// The server will produce audio faster than realtime, so this event is useful when the user interrupts to truncate audio that has already been sent to the client but not yet played.
	///
	/// This will synchronize the server's understanding of the audio with the client's playback.
	///
	/// Truncating audio will delete the server-side text transcript to ensure there is not text in the context that hasn't been heard by the user.
	///
	/// If successful, the server will respond with a `conversationItemTruncated` event.
	///
	/// - Parameter itemId: The ID of the assistant message item to truncate. Only assistant message items can be truncated.
	/// - Parameter contentIndex: The index of the content part to truncate.
	/// - Parameter audioEndMs: Inclusive duration up to which audio is truncated, in milliseconds.
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	static func truncateConversationItem(forItem itemId: String? = nil, at contentIndex: Int = 0, atAudioMs audioEndMs: Int, withEventId eventId: String? = nil) -> ClientEvent {
		.truncateConversationItem(eventId: eventId, itemId: itemId, contentIndex: contentIndex, audioEndMs: audioEndMs)
	}

	/// Send this event when you want to remove any item from the conversation history.
	///
	/// The server will respond with a `conversationItemDeleted` event, unless the item does not exist in the conversation history, in which case the server will respond with an error.
	///
	/// - Parameter itemId: The ID of the item to delete.
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	static func deleteConversationItem(by itemId: String? = nil, withEventId eventId: String? = nil) -> ClientEvent {
		.deleteConversationItem(eventId: eventId, itemId: itemId)
	}

	/// This event instructs the server to create a Response, which means triggering model inference.
	///
	/// When in Server VAD mode, the server will create Responses automatically.
	///
	/// A Response will include at least one Item, and may have two, in which case the second will be a function call.
	/// These Items will be appended to the conversation history.
	///
	/// The server will respond with a `responseCreated` event, events for created Items and content, and finally a `responseDone` event to indicate the Response is complete.
	///
	/// The `createResponse` event includes inference configuration like `instructions`, and `temperature`.
	/// These fields will override the Session's configuration for this Response only.
	///
	/// - Parameter response: Configuration for the response.
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	static func createResponse(using response: Response.Config? = nil, withEventId eventId: String? = nil) -> ClientEvent {
		.createResponse(eventId: eventId, response: response)
	}

	/// Send this event to cancel an in-progress response.
	///
	/// The server will respond with a `responseDone` event with a status of `cancelled`.
	/// If there is no response to cancel, the server will respond with an error.
	///
	/// - Parameter responseId: A specific response ID to cancel - if not provided, will cancel an in-progress response in the default conversation.
	/// - Parameter eventId: Optional client-generated ID used to identify this event.
	static func cancelResponse(by responseId: String? = nil, withEventId eventId: String? = nil) -> ClientEvent {
		.cancelResponse(eventId: eventId, responseId: responseId)
	}

	/// WebRTC Only: Emit to cut off the current audio response.
	///
	/// This will trigger the server to stop generating audio and emit a `outputAudioBufferCleared` event.
	///
	/// This event should be preceded by a `cancelResponse` client event to stop the generation of the current response. [Learn more](https://platform.openai.com/docs/guides/realtime-conversations#client-and-server-events-for-audio-in-webrtc).
	static func outputAudioBufferClear(withEventId eventId: String? = nil) -> ClientEvent {
		.outputAudioBufferClear(eventId: eventId)
	}
}
