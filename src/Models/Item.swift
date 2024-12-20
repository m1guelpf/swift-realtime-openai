import Foundation

public enum Item: Identifiable, Equatable, Sendable {
	public enum ItemStatus: String, Codable, Sendable {
		case completed
		case in_progress
		case incomplete
	}

	public enum ItemRole: String, Codable, Sendable {
		case user
		case system
		case assistant
	}

	public struct Audio: Equatable, Sendable {
		/// Base64-encoded audio bytes.
		public var audio: Data
		/// The transcript of the audio.
		public var transcript: String?

		public init(audio: Data = Data(), transcript: String? = nil) {
			self.audio = audio
			self.transcript = transcript
		}
	}

	public enum ContentPart: Equatable, Sendable {
		case text(String)
		case audio(Audio)
	}

	public struct Message: Codable, Equatable, Sendable {
		public enum Content: Equatable, Sendable {
			case text(String)
			case audio(Audio)
			case input_text(String)
			case input_audio(Audio)

			public var text: String? {
				switch self {
					case let .text(text):
						return text
					case let .input_text(text):
						return text
					case let .input_audio(audio):
						return audio.transcript
					case let .audio(audio):
						return audio.transcript
				}
			}
		}

		/// The unique ID of the item.
		public var id: String
		/// The type of the item
		private var type: String = "message"
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

	public struct FunctionCall: Codable, Equatable, Sendable {
		/// The unique ID of the item.
		public var id: String
		/// The type of the item
		private var type: String = "function_call"
		/// The status of the item
		public var status: ItemStatus
		/// The ID of the function call
		public var callId: String
		/// The name of the function being called
		public var name: String
		/// The arguments of the function call
		public var arguments: String
	}

	public struct FunctionCallOutput: Codable, Equatable, Sendable {
		/// The unique ID of the item.
		public var id: String
		/// The type of the item
		private var type: String = "function_call_output"
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
	case functionCall(FunctionCall)
	case functionCallOutput(FunctionCallOutput)

	public var id: String {
		switch self {
			case let .message(message):
				return message.id
			case let .functionCall(functionCall):
				return functionCall.id
			case let .functionCallOutput(functionCallOutput):
				return functionCallOutput.id
		}
	}

	public init(message: Message) {
		self = .message(message)
	}

	public init(calling functionCall: FunctionCall) {
		self = .functionCall(functionCall)
	}

	public init(with functionCallOutput: FunctionCallOutput) {
		self = .functionCallOutput(functionCallOutput)
	}
}

// MARK: Helpers

public extension Item.Message.Content {
	init(from part: Item.ContentPart) {
		switch part {
			case let .audio(audio):
				self = .audio(audio)
			case let .text(text):
				self = .text(text)
		}
	}
}

// MARK: Codable implementations

extension Item: Codable {
	private enum CodingKeys: String, CodingKey {
		case type
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)

		switch type {
			case "message":
				self = try .message(Message(from: decoder))
			case "function_call":
				self = try .functionCall(FunctionCall(from: decoder))
			case "function_call_output":
				self = try .functionCallOutput(FunctionCallOutput(from: decoder))
			default:
				throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown item type: \(type)")
		}
	}

	public func encode(to encoder: Encoder) throws {
		switch self {
			case let .message(message):
				try message.encode(to: encoder)
			case let .functionCall(functionCall):
				try functionCall.encode(to: encoder)
			case let .functionCallOutput(functionCallOutput):
				try functionCallOutput.encode(to: encoder)
		}
	}
}

extension Item.Audio: Decodable {
	private enum CodingKeys: String, CodingKey {
		case audio
		case transcript
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		transcript = try container.decodeIfPresent(String.self, forKey: .transcript)
		let encodedAudio = try container.decodeIfPresent(String.self, forKey: .audio)

		if let encodedAudio {
			guard let decodedAudio = Data(base64Encoded: encodedAudio) else {
				throw DecodingError.dataCorruptedError(forKey: .audio, in: container, debugDescription: "Invalid base64-encoded audio data.")
			}
			audio = decodedAudio
		} else {
			audio = Data()
		}
	}
}

extension Item.ContentPart: Decodable {
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
				try container.encode(audio.transcript, forKey: .transcript)
				try container.encode(audio.audio.base64EncodedString(), forKey: .audio)
			case let .input_audio(audio):
				try container.encode("input_audio", forKey: .type)
				try container.encode(audio.transcript, forKey: .transcript)
				try container.encode(audio.audio.base64EncodedString(), forKey: .audio)
		}
	}
}
