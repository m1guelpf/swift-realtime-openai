import Foundation
import MetaCodable

@Codable @CodedAt("type") public enum Item: Identifiable, Equatable, Hashable, Sendable {
	public enum ItemStatus: String, Equatable, Hashable, Codable, Sendable {
		case completed, incomplete, inProgress = "in_progress"
	}

	public enum ItemRole: String, Equatable, Hashable, Codable, Sendable {
		case system, assistant, user
	}

	public struct Audio: Equatable, Hashable, Codable, Sendable {
		/// Audio bytes
		public var audio: AudioData

		/// The transcript of the audio
		public var transcript: String?

		public init(audio: AudioData, transcript: String? = nil) {
			self.audio = audio
			self.transcript = transcript
		}

		public init(audio: Data = Data(), transcript: String? = nil) {
			self.init(audio: AudioData(data: audio), transcript: transcript)
		}
	}

	public enum ContentPart: Equatable, Hashable, Sendable {
		case text(String)
		case audio(Audio)
	}

	public struct Message: Identifiable, Equatable, Hashable, Codable, Sendable {
		public enum Content: Equatable, Hashable, Sendable {
			case text(String)
			case audio(Audio)
			case input_text(String)
			case input_audio(Audio)

			public var text: String? {
				switch self {
					case let .text(text): text
					case let .input_text(text): text
					case let .audio(audio): audio.transcript
					case let .input_audio(audio): audio.transcript
				}
			}
		}

		/// The unique ID of the item.
		public var id: String

		/// The status of the item
		public var status: ItemStatus

		/// The role associated with the item
		public var role: ItemRole

		/// The content of the message.
		public var content: [Content]

		public init(id: String, from role: ItemRole, content: [Content]) {
			self.id = id
			self.role = role
			status = .completed
			self.content = content
		}
	}

	public struct FunctionCall: Identifiable, Equatable, Hashable, Codable, Sendable {
		/// The unique ID of the item.
		public var id: String

		/// The status of the item
		public var status: ItemStatus

		/// The ID of the function call
		public var callId: String

		/// The name of the function being called
		public var name: String

		/// The arguments of the function call
		public var arguments: String
	}

	public struct FunctionCallOutput: Identifiable, Equatable, Hashable, Codable, Sendable {
		/// The unique ID of the item.
		public var id: String

		/// The ID of the function call
		public var callId: String

		/// The output of the function call
		public var output: String

		public init(id: String, callId: String, output: String) {
			self.id = id
			self.callId = callId
			self.output = output
		}
	}

	case message(Message)

	@CodedAs("function_call")
	case functionCall(FunctionCall)

	@CodedAs("function_call_output")
	case functionCallOutput(FunctionCallOutput)

	public var id: String {
		switch self {
			case let .message(message): message.id
			case let .functionCall(functionCall): functionCall.id
			case let .functionCallOutput(functionCallOutput): functionCallOutput.id
		}
	}
}

// MARK: Helpers

public extension Item.Message.Content {
	init(from part: Item.ContentPart) {
		switch part {
			case let .text(text): self = .text(text)
			case let .audio(audio): self = .audio(audio)
		}
	}
}

// MARK: Codable implementations

extension Item.ContentPart: Codable {
	private enum CodingKeys: String, CodingKey {
		case type
		case text
		case audio
		case transcript
	}

	private struct Text: Codable {
		let text: String

		enum CodingKeys: CodingKey {
			case text
		}
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)

		switch type {
			case "text":
				let container = try decoder.container(keyedBy: Text.CodingKeys.self)
				self = try .text(container.decode(String.self, forKey: .text))
			case "audio":
				self = try .audio(Item.Audio(from: decoder))
			default:
				throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown content type: \(type)")
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
			case let .text(text):
				try container.encode(text, forKey: .text)
				try container.encode("text", forKey: .type)
			case let .audio(audio):
				try container.encode("audio", forKey: .type)
				try container.encode(audio.transcript, forKey: .transcript)
				try container.encode(audio.audio, forKey: .audio)
		}
	}
}

extension Item.Message.Content: Codable {
	private enum CodingKeys: String, CodingKey {
		case type
		case text
		case audio
		case transcript
	}

	private struct Text: Codable {
		let text: String

		enum CodingKeys: CodingKey {
			case text
		}
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)

		switch type {
			case "text":
				let container = try decoder.container(keyedBy: Text.CodingKeys.self)
				self = try .text(container.decode(String.self, forKey: .text))
			case "input_text":
				let container = try decoder.container(keyedBy: Text.CodingKeys.self)
				self = try .input_text(container.decode(String.self, forKey: .text))
			case "audio":
				self = try .audio(Item.Audio(from: decoder))
			case "input_audio":
				self = try .input_audio(Item.Audio(from: decoder))
			default:
				throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown content type: \(type)")
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
			case let .text(text):
				try container.encode(text, forKey: .text)
				try container.encode("text", forKey: .type)
			case let .input_text(text):
				try container.encode(text, forKey: .text)
				try container.encode("input_text", forKey: .type)
			case let .audio(audio):
				try container.encode("audio", forKey: .type)
				try container.encode(audio.audio, forKey: .audio)
				try container.encode(audio.transcript, forKey: .transcript)
			case let .input_audio(audio):
				try container.encode(audio.audio, forKey: .audio)
				try container.encode("input_audio", forKey: .type)
				try container.encode(audio.transcript, forKey: .transcript)
		}
	}
}
