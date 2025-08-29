import Foundation
import MetaCodable
import HelperCoders

@Codable public struct Session: Equatable, Hashable, Sendable {
	public enum Modality: String, Equatable, Hashable, Codable, Sendable {
		case text, audio
	}

	public enum MaxResponseOutputTokens: Equatable, Hashable, Sendable, Codable {
		case inf
		case limited(Int)

		public func encode(to encoder: any Encoder) throws {
			var container = encoder.singleValueContainer()

			switch self {
				case .inf: try container.encode("inf")
				case let .limited(value): try container.encode(value)
			}
		}

		public init(from decoder: any Decoder) throws {
			let container = try decoder.singleValueContainer()

			if let stringValue = try? container.decode(String.self), stringValue == "inf" {
				self = .inf
				return
			}

			if let intValue = try? container.decode(Int.self) {
				self = .limited(intValue)
				return
			}

			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Failed to decode MaxResponseOutputTokens")
		}
	}

	public struct Prompt: Equatable, Hashable, Codable, Sendable {
		/// The unique identifier of the prompt template to use.
		public var id: String

		/// Optional version of the prompt template.
		public var version: String?

		/// Optional map of values to substitute in for variables in your prompt.
		///
		/// The substitution values can either be strings, or other Response input types like images or files.
		public var variables: [String: String]?
	}

	public enum Voice: String, CaseIterable, Equatable, Hashable, Codable, Sendable {
		case alloy, ash, ballad, coral, echo, sage, shimmer, verse
	}

	/// The format of input audio.
	public struct AudioFormat: Equatable, Hashable, Codable, Sendable {
		public var rate: Int
		public var type: String
	}

	public struct Audio: Codable, Equatable, Hashable, Sendable {
		public struct Input: Equatable, Hashable, Codable, Sendable {
			public struct Transcription: Codable, Equatable, Hashable, Sendable {
				public enum TranscriptionModel: String, CaseIterable, Equatable, Hashable, Codable, Sendable {
					case whisper = "whisper-1"
					case gpt4o = "gpt-4o-transcribe"
					case gpt4oMini = "gpt-4o-mini-transcribe"
				}

				/// The model to use for transcription
				public var model: TranscriptionModel

				/// The language of the input audio. Supplying the input language in ISO-639-1 (e.g. `en`) format will improve accuracy and latency.
				public var language: String?

				/// An optional text to guide the model's style or continue a previous audio segment.
				///
				/// For `whisper`, the [prompt is a list of keywords](https://platform.openai.com/docs/guides/speech-to-text#prompting). For `gpt4o` models, the prompt is a free text string, for example "expect words related to technology".
				public var prompt: String?

				public init(model: TranscriptionModel = .whisper) {
					self.model = model
				}
			}

			public struct NoiseReduction: Codable, Equatable, Hashable, Sendable {
				/// Type of noise reduction.
				public enum NoiseReductionType: String, CaseIterable, Hashable, Codable, Sendable {
					/// For close-talking microphones such as headphones
					case nearField = "near_field"

					/// For far-field microphones such as laptop or conference room microphones
					case farField = "far_field"
				}

				/// Type of noise reduction.
				public var type: NoiseReductionType?

				public init(type: NoiseReductionType? = nil) {
					self.type = type
				}
			}

			public struct TurnDetection: Codable, Equatable, Hashable, Sendable {
				public enum TurnDetectionType: String, Codable, Equatable, Hashable, Sendable {
					case none
					case serverVad = "server_vad"
					case semanticVad = "semantic_vad"
				}

				public enum TurnDetectionEagerness: String, CaseIterable, Equatable, Hashable, Codable, Sendable {
					case auto, low, medium, high
				}

				/// The type of turn detection.
				public var type: TurnDetectionType
				/// Used only for `server_vad` mode. Activation threshold for VAD (0.0 to 1.0).
				public var threshold: Double?
				/// Whether or not to automatically interrupt any ongoing response with output to the default conversation (i.e. `conversation` of `auto`) when a VAD start event occurs.
				public var interruptResponse: Bool?
				/// Used only for `server_vad` mode. Amount of audio to include before speech starts (in milliseconds).
				public var prefixPaddingMs: Int?
				/// Used only for `server_vad` mode. Duration of silence to detect speech stop (in milliseconds).
				public var silenceDurationMs: Int?
				/// Whether or not to automatically generate a response when VAD is enabled.
				public var createResponse: Bool
				/// Used only for `semantic_vad` mode. The eagerness of the model to respond. `low` will wait longer for the user to continue speaking, `high` will respond more quickly. `auto` is the default and is equivalent to `medium`.
				public var eagerness: TurnDetectionEagerness?

				public init(type: TurnDetectionType = .serverVad, threshold: Double? = nil, interruptResponse: Bool? = nil, prefixPaddingMs: Int? = nil, silenceDurationMs: Int? = nil, createResponse: Bool = true, eagerness: TurnDetectionEagerness? = nil) {
					self.type = type
					self.eagerness = eagerness
					self.threshold = threshold
					self.createResponse = createResponse
					self.prefixPaddingMs = prefixPaddingMs
					self.silenceDurationMs = silenceDurationMs
					self.interruptResponse = interruptResponse
				}

				public static func serverVad(threshold: Double? = nil, interruptResponse: Bool? = nil, prefixPaddingMs: Int? = nil, silenceDurationMs: Int? = nil) -> TurnDetection {
					.init(type: .serverVad, threshold: threshold, interruptResponse: interruptResponse, prefixPaddingMs: prefixPaddingMs, silenceDurationMs: silenceDurationMs)
				}

				public static func semanticVad(eagerness: TurnDetectionEagerness = .auto) -> TurnDetection {
					.init(type: .semanticVad, eagerness: eagerness)
				}
			}

			public var format: AudioFormat
			public var transcription: Transcription?
			public var turnDetection: TurnDetection?
			public var noiseReduction: NoiseReduction?
		}

		public struct Output: Equatable, Hashable, Codable, Sendable {
			public var voice: Voice
			public var speed: Double
			public var format: AudioFormat
		}

		public var input: Input
		public var output: Output
	}

	public struct Tool: Codable, Equatable, Hashable, Sendable {
		public struct FunctionParameters: Codable, Equatable, Hashable, Sendable {
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

			public struct Property: Codable, Equatable, Hashable, Sendable {
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

				public struct Items: Codable, Equatable, Hashable, Sendable {
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

			public enum JSONType: String, Codable, Equatable, Hashable, Sendable {
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

	public enum ToolChoice: Equatable, Hashable, Sendable {
		case auto
		case none
		case required
		case function(String)

		public init(function name: String) {
			self = .function(name)
		}
	}

	/// Expiration timestamp for the session
	@CodedBy(Since1970DateCoder())
	public var expiresAt: Date

	/// Unique identifier for the session
	public var id: String?

	public var audio: Audio

	/// The default system instructions (i.e. system message) prepended to model calls.
	///
	/// This field allows the client to guide the model on desired responses.
	///
	/// The model can be instructed on response content and format, (e.g. "be extremely succinct", "act friendly", "here are examples of good responses") and on audio behavior (e.g. "talk quickly", "inject emotion into your voice", "laugh frequently").
	///
	/// The instructions are not guaranteed to be followed by the model, but they provide guidance to the model on the desired behavior.
	public var instructions: String

	/// Maximum number of output tokens for a single assistant response, inclusive of tool calls.
	///
	/// Provide an integer between 1 and 4096 to limit output tokens, or `inf` for the maximum available tokens for a given model.
	public var maxResponseOutputTokens: MaxResponseOutputTokens?

	/// The set of modalities the model can respond with.
	public var modalities: [Modality]?

	/// The Realtime model used for this session.
	public var model: Model

	/// Reference to a prompt template and its variables.
	public var prompt: Prompt?

	/// Sampling temperature for the model, limited to [0.6, 1.2].
	///
	/// For audio models a temperature of 0.8 is highly recommended for best performance.
	public var temperature: Double?

	/// How the model chooses tools.
	public var toolChoice: ToolChoice?

	/// Tools (functions) available to the model.
	public var tools: [Tool]?

	public init(expiresAt: Date, id: String? = nil, audio: Audio, instructions: String, maxResponseOutputTokens: MaxResponseOutputTokens? = nil, modalities: [Modality]? = nil, model: Model, prompt: Prompt? = nil, temperature: Double? = nil, toolChoice: ToolChoice? = nil, tools: [Tool]? = nil) {
		self.expiresAt = expiresAt
		self.id = id
		self.audio = audio
		self.instructions = instructions
		self.maxResponseOutputTokens = maxResponseOutputTokens
		self.modalities = modalities
		self.model = model
		self.prompt = prompt
		self.temperature = temperature
		self.toolChoice = toolChoice
		self.tools = tools
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
