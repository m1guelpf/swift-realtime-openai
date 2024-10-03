public struct Session: Codable, Sendable {
	public enum Modality: String, Codable, Sendable {
		case text
		case audio
	}

	public enum Voice: String, Codable, Sendable {
		case alloy
		case echo
		case fable
		case onyx
		case nova
		case shimmer
	}

	public enum AudioFormat: String, Codable, Sendable {
		case pcm16
		case g711_ulaw
		case g711_alaw
	}

	public struct InputAudioTranscription: Codable, Sendable {
		public let enabled: Bool
		public let model: String
	}

	public struct TurnDetection: Codable, Sendable {
		public enum TurnDetectionType: String, Codable, Sendable {
			case server_vad
			case none
		}

		/// The type of turn detection.
		public let type: TurnDetectionType
		/// Activation threshold for VAD (0.0 to 1.0).
		public let threshold: Double
		/// Amount of audio to include before speech starts (in milliseconds).
		public let prefix_padding_ms: Int
		/// Duration of silence to detect speech stop (in milliseconds).
		public let silence_duration_ms: Int
	}

	public struct Tool: Codable, Sendable {
		public struct FunctionParameters: Codable, Equatable, Sendable {
			public let type: JSONType
			public let properties: [String: Property]?
			public let required: [String]?
			public let pattern: String?
			public let const: String?
			public let `enum`: [String]?
			public let multipleOf: Int?
			public let minimum: Int?
			public let maximum: Int?

			public init(
				type: JSONType,
				properties: [String: Property]? = nil,
				required: [String]? = nil,
				pattern: String? = nil,
				const: String? = nil,
				enum: [String]? = nil,
				multipleOf: Int? = nil,
				minimum: Int? = nil,
				maximum: Int? = nil
			) {
				self.type = type
				self.properties = properties
				self.required = required
				self.pattern = pattern
				self.const = const
				self.enum = `enum`
				self.multipleOf = multipleOf
				self.minimum = minimum
				self.maximum = maximum
			}

			public struct Property: Codable, Equatable, Sendable {
				public let type: JSONType
				public let description: String?
				public let format: String?
				public let items: Items?
				public let required: [String]?
				public let pattern: String?
				public let const: String?
				public let `enum`: [String]?
				public let multipleOf: Int?
				public let minimum: Double?
				public let maximum: Double?
				public let minItems: Int?
				public let maxItems: Int?
				public let uniqueItems: Bool?

				public init(
					type: JSONType,
					description: String? = nil,
					format: String? = nil,
					items: Self.Items? = nil,
					required: [String]? = nil,
					pattern: String? = nil,
					const: String? = nil,
					enum: [String]? = nil,
					multipleOf: Int? = nil,
					minimum: Double? = nil,
					maximum: Double? = nil,
					minItems: Int? = nil,
					maxItems: Int? = nil,
					uniqueItems: Bool? = nil
				) {
					self.type = type
					self.description = description
					self.format = format
					self.items = items
					self.required = required
					self.pattern = pattern
					self.const = const
					self.enum = `enum`
					self.multipleOf = multipleOf
					self.minimum = minimum
					self.maximum = maximum
					self.minItems = minItems
					self.maxItems = maxItems
					self.uniqueItems = uniqueItems
				}

				public struct Items: Codable, Equatable, Sendable {
					public let type: JSONType
					public let properties: [String: Property]?
					public let pattern: String?
					public let const: String?
					public let `enum`: [String]?
					public let multipleOf: Int?
					public let minimum: Double?
					public let maximum: Double?
					public let minItems: Int?
					public let maxItems: Int?
					public let uniqueItems: Bool?

					public init(
						type: JSONType,
						properties: [String: Property]? = nil,
						pattern: String? = nil,
						const: String? = nil,
						enum: [String]? = nil,
						multipleOf: Int? = nil,
						minimum: Double? = nil,
						maximum: Double? = nil,
						minItems: Int? = nil,
						maxItems: Int? = nil,
						uniqueItems: Bool? = nil
					) {
						self.type = type
						self.properties = properties
						self.pattern = pattern
						self.const = const
						self.enum = `enum`
						self.multipleOf = multipleOf
						self.minimum = minimum
						self.maximum = maximum
						self.minItems = minItems
						self.maxItems = maxItems
						self.uniqueItems = uniqueItems
					}
				}
			}

			public enum JSONType: String, Codable, Sendable {
				case integer
				case string
				case boolean
				case array
				case object
				case number
				case null
			}
		}

		/// The type of the tool.
		public let type: String
		/// The name of the function.
		public let name: String
		/// The description of the function.
		public let description: String
		/// Parameters of the function in JSON Schema.
		public let parameters: FunctionParameters
	}

	public enum ToolChoice: Codable, Sendable {
		case auto
		case none
		case required
		case function(String)

		public init(function name: String) {
			self = .function(name)
		}

		private enum FunctionCall: Codable, Equatable {
			case type
			case function

			enum CodingKeys: CodingKey {
				case type
				case function
			}
		}

		public init(from decoder: any Decoder) throws {
			let container = try decoder.singleValueContainer()

			if let stringValue = try? container.decode(String.self) {
				switch stringValue {
					case "none":
						self = .none
					case "auto":
						self = .auto
					case "required":
						self = .required
					default:
						throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid value for enum.")
				}
			} else {
				let container = try decoder.container(keyedBy: FunctionCall.CodingKeys.self)
				let functionContainer = try container.decode([String: String].self, forKey: .function)

				guard let name = functionContainer["name"] else {
					throw DecodingError.dataCorruptedError(forKey: .function, in: container, debugDescription: "Missing function name.")
				}

				self = .function(name)
			}
		}

		public func encode(to encoder: Encoder) throws {
			switch self {
				case .none:
					var container = encoder.singleValueContainer()
					try container.encode("none")
				case .auto:
					var container = encoder.singleValueContainer()
					try container.encode("auto")
				case .required:
					var container = encoder.singleValueContainer()
					try container.encode("required")
				case let .function(name):
					var container = encoder.container(keyedBy: FunctionCall.CodingKeys.self)
					try container.encode("function", forKey: .type)
					try container.encode(["name": name], forKey: .function)
			}
		}
	}

	/// The unique ID of the session.
	public let id: String
	/// The default model used for this session.
	public let model: String
	/// The set of modalities the model can respond with.
	public let modalities: [Modality]
	/// The default system instructions.
	public let instructions: String
	/// The voice the model uses to respond.
	public let voice: Voice
	/// The format of input audio.
	public let input_audio_format: AudioFormat
	/// The format of output audio.
	public let output_audio_format: AudioFormat
	/// Configuration for input audio transcription.
	public let input_audio_transcription: InputAudioTranscription?
	/// Configuration for turn detection.
	public let turn_detection: TurnDetection?
	/// Tools (functions) available to the model.
	public let tools: [Tool]
	/// How the model chooses tools.
	public let tool_choice: ToolChoice
	/// Sampling temperature.
	public let temperature: Double
	/// Maximum number of output tokens.
	public let max_output_tokens: Int?
}
