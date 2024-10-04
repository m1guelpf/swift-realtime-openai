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

	public struct Audio: Codable, Equatable, Sendable {
		/// Base64-encoded audio bytes.
		public var audio: String?
		/// The transcript of the audio.
		public var transcript: String?
	}

	public enum ContentPart: Codable, Equatable, Sendable {
		case text(String)
		case audio(Audio)

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
					self = try .audio(Audio(from: decoder))
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
					try container.encode(audio.audio, forKey: .audio)
					try container.encode(audio.transcript, forKey: .transcript)
			}
		}
	}

	public struct Message: Codable, Equatable, Sendable {
		public enum Content: Codable, Equatable, Sendable {
			case text(String)
			case audio(Audio)
			case input_text(String)
			case input_audio(Audio)

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
						self = try .audio(Audio(from: decoder))
					case "input_audio":
						self = try .input_audio(Audio(from: decoder))
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
		/// The role associated with the item
		public var role: ItemRole
		/// The ID of the function call
		public var call_id: String
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
		/// The status of the item
		public var status: ItemStatus
		/// The role associated with the item
		public var role: ItemRole
		/// The ID of the function call
		public var call_id: String
		/// The output of the function call
		public var output: String
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
