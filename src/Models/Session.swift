public struct Session: Codable, Equatable, Sendable {
	public enum Modality: String, Codable, Sendable {
		case text
		case audio
	}

	public enum Voice: String, Codable, Sendable {
		case alloy
		case echo
		case shimmer
		case ash
		case ballad
		case coral
		case sage
		case verse
	}

	public enum AudioFormat: String, Codable, Sendable {
		case pcm16
		case g711_ulaw
		case g711_alaw
	}

	public struct InputAudioTranscription: Codable, Equatable, Sendable {
		public var model: String

		public init(model: String = "whisper-1") {
			self.model = model
		}
	}

	public struct TurnDetection: Codable, Equatable, Sendable {
		public enum TurnDetectionType: String, Codable, Sendable {
			case serverVad = "server_vad"
			case none
		}

		/// The type of turn detection.
		public var type: TurnDetectionType
		/// Activation threshold for VAD (0.0 to 1.0).
		public var threshold: Double
		/// Amount of audio to include before speech starts (in milliseconds).
		public var prefixPaddingMs: Int
		/// Duration of silence to detect speech stop (in milliseconds).
		public var silenceDurationMs: Int
		/// Whether or not to automatically generate a response when VAD is enabled.
		public var createResponse: Bool

		public init(
			type: TurnDetectionType = .serverVad,
			threshold: Double = 0.5,
			prefixPaddingMs: Int = 300,
			silenceDurationMs: Int = 500,
			createResponse: Bool = true
		) {
			self.type = type
			self.threshold = threshold
			self.createResponse = createResponse
			self.prefixPaddingMs = prefixPaddingMs
			self.silenceDurationMs = silenceDurationMs
		}
	}

	public struct Tool: Codable, Equatable, Sendable {
		public struct FunctionParameters: Codable, Equatable, Sendable {
			public var type: JSONType
			public var properties: [String: Property]?
			public var required: [String]?
			public var pattern: String?
			public var const: String?
			public var `enum`: [String]?
			public var multipleOf: Int?
			public var minimum: Int?
			public var maximum: Int?

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
				public var type: JSONType
				public var description: String?
				public var format: String?
				public var items: Items?
				public var required: [String]?
				public var pattern: String?
				public var const: String?
				public var `enum`: [String]?
				public var multipleOf: Int?
				public var minimum: Double?
				public var maximum: Double?
				public var minItems: Int?
				public var maxItems: Int?
				public var uniqueItems: Bool?

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
					public var type: JSONType
					public var properties: [String: Property]?
					public var pattern: String?
					public var const: String?
					public var `enum`: [String]?
					public var multipleOf: Int?
					public var minimum: Double?
					public var maximum: Double?
					public var minItems: Int?
					public var maxItems: Int?
					public var uniqueItems: Bool?

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
		public var type: String = "function"
		/// The name of the function.
		public var name: String
		/// The description of the function.
		public var description: String
		/// Parameters of the function in JSON Schema.
		public var parameters: FunctionParameters

		public init(type: String = "function", name: String, description: String, parameters: FunctionParameters) {
			self.type = type
			self.name = name
			self.description = description
			self.parameters = parameters
		}
	}

	public enum ToolChoice: Equatable, Sendable {
		case auto
		case none
		case required
		case function(String)

		public init(function name: String) {
			self = .function(name)
		}
	}

	/// The unique ID of the session.
	public var id: String?
	/// The default model used for this session.
	public var model: String
	/// The set of modalities the model can respond with.
	public var modalities: [Modality]
	/// The default system instructions.
	public var instructions: String
	/// The voice the model uses to respond.
	public var voice: Voice
	/// The format of input audio.
	public var inputAudioFormat: AudioFormat
	/// The format of output audio.
	public var outputAudioFormat: AudioFormat
	/// Configuration for input audio transcription.
	public var inputAudioTranscription: InputAudioTranscription?
	/// Configuration for turn detection.
	public var turnDetection: TurnDetection?
	/// Tools (functions) available to the model.
	public var tools: [Tool]
	/// How the model chooses tools.
	public var toolChoice: ToolChoice
	/// Sampling temperature.
	public var temperature: Double
	/// Maximum number of output tokens.
	public var maxOutputTokens: Int?

	public init(
		id: String? = nil,
		model: String,
		tools: [Tool] = [],
		instructions: String,
		voice: Voice = .alloy,
		temperature: Double = 1,
		maxOutputTokens: Int? = nil,
		toolChoice: ToolChoice = .auto,
		turnDetection: TurnDetection? = nil,
		inputAudioFormat: AudioFormat = .pcm16,
		outputAudioFormat: AudioFormat = .pcm16,
		modalities: [Modality] = [.text, .audio],
		inputAudioTranscription: InputAudioTranscription? = nil
	) {
		self.id = id
		self.model = model
		self.tools = tools
		self.voice = voice
		self.toolChoice = toolChoice
		self.modalities = modalities
		self.temperature = temperature
		self.instructions = instructions
		self.turnDetection = turnDetection
		self.maxOutputTokens = maxOutputTokens
		self.inputAudioFormat = inputAudioFormat
		self.outputAudioFormat = outputAudioFormat
		self.inputAudioTranscription = inputAudioTranscription
	}
}

extension Session.ToolChoice: Codable {
	private enum FunctionCall: Codable {
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
