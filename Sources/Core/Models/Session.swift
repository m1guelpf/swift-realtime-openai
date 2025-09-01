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
		case alloy, ash, ballad, coral, echo, sage, shimmer, verse, marin, cedar
	}

	/// The format of input audio.
	public struct AudioFormat: Equatable, Hashable, Codable, Sendable {
		public var rate: Int
		public var type: String
	}

	/// Configuration for input and output audio.
	public struct Audio: Codable, Equatable, Hashable, Sendable {
		/// Configuration for input audio.
		public struct Input: Equatable, Hashable, Codable, Sendable {
			/// Configuration for input audio transcription.
			public struct Transcription: Equatable, Hashable, Codable, Sendable {
				/// The model to use for transcription
				public var model: Model.Transcription

				/// The language of the input audio. Supplying the input language in ISO-639-1 (e.g. `en`) format will improve accuracy and latency.
				public var language: String?

				/// An optional text to guide the model's style or continue a previous audio segment.
				///
				/// For `whisper`, the [prompt is a list of keywords](https://platform.openai.com/docs/guides/speech-to-text#prompting).
				/// For `gpt4o` models, the prompt is a free text string, for example "expect words related to technology".
				public var prompt: String?

				public init(model: Model.Transcription = .gpt4o, language: String? = nil, prompt: String? = nil) {
					self.model = model
					self.prompt = prompt
					self.language = language
				}
			}

			/// Configuration for input audio noise reduction.
			public enum NoiseReduction: String, CaseIterable, Equatable, Hashable, Sendable {
				/// For close-talking microphones such as headphones
				case nearField = "near_field"

				/// For far-field microphones such as laptop or conference room microphones
				case farField = "far_field"
			}

			/// Configuration for turn detection
			public struct TurnDetection: Codable, Equatable, Hashable, Sendable {
				/// The type of turn detection.
				public enum VAD: String, Codable, Equatable, Hashable, Sendable {
					case server = "server_vad"
					case semantic = "semantic_vad"
				}

				/// The eagerness of the model to respond.
				public enum Eagerness: String, CaseIterable, Equatable, Hashable, Codable, Sendable {
					case auto, low, medium, high
				}

				/// Whether or not to automatically generate a response when a VAD stop event occurs.
				public var createResponse: Bool

				/// Used only for `semantic` mode. The eagerness of the model to respond.
				///
				/// `low` will wait longer for the user to continue speaking, `high` will respond more quickly. `auto` is the default and is equivalent to `medium`.
				public var eagerness: Eagerness?

				/// Optional idle timeout after which turn detection will auto-timeout when no additional audio is received.
				public var idleTimeout: Int?

				/// Whether or not to automatically interrupt any ongoing response with output to the default conversation (i.e. `conversation` of `auto`) when a VAD start event occurs.
				public var interruptResponse: Bool?

				/// Used only for `server` mode. Amount of audio to include before speech starts (in milliseconds).
				///
				/// Defaults to `300ms`.
				public var prefixPaddingMs: Int?

				/// Used only for `server` mode. Duration of silence to detect speech stop (in milliseconds).
				///
				/// Defaults to `500ms`.
				///
				/// With shorter values the model will respond more quickly, but may jump in on short pauses from the user.
				public var silenceDurationMs: Int?

				/// Used only for `server` mode. Activation threshold for VAD (0.0 to 1.0).
				///
				/// A higher threshold will require louder audio to activate the model, and thus might perform better in noisy environments.
				public var threshold: Double?

				/// The type of turn detection.
				public var type: VAD

				/// Creates a new `TurnDetection` configuration.
				///
				/// - Parameter createResponse: Whether or not to automatically generate a response when a VAD stop event occurs.
				/// - Parameter eagerness: Only for `semantic` mode. The eagerness of the model to respond.
				/// - Parameter idleTimeout: Optional idle timeout after which turn detection will auto-timeout when no additional audio is received.
				/// - Parameter interruptResponse: Whether or not to automatically interrupt any ongoing response with output to the default conversation when a VAD start event occurs.
				/// - Parameter prefixPaddingMs: Only for `server` mode. Amount of audio to include before speech starts (in milliseconds).
				/// - Parameter silenceDurationMs: Only for `server` mode. Duration of silence to detect speech stop (in milliseconds).
				/// - Parameter threshold: Only for `server` mode. Activation threshold for VAD (0.0 to 1.0).
				/// - Parameter type: The type of turn detection.
				public init(createResponse: Bool = true, eagerness: Eagerness? = nil, idleTimeout: Int? = nil, interruptResponse: Bool? = nil, prefixPaddingMs: Int? = nil, silenceDurationMs: Int? = nil, threshold: Double? = nil, type: VAD = .server) {
					self.createResponse = createResponse
					self.eagerness = eagerness
					self.idleTimeout = idleTimeout
					self.interruptResponse = interruptResponse
					self.prefixPaddingMs = prefixPaddingMs
					self.silenceDurationMs = silenceDurationMs
					self.threshold = threshold
					self.type = type
				}

				/// Creates a new `TurnDetection` configuration for Server VAD.
				///
				/// - Parameter createResponse: Whether or not to automatically generate a response when a VAD stop event occurs.
				/// - Parameter idleTimeout: Optional idle timeout after which turn detection will auto-timeout when no additional audio is received.
				/// - Parameter interruptResponse: Whether or not to automatically interrupt any ongoing response with output to the default conversation when a VAD start event occurs.
				/// - Parameter prefixPaddingMs: Amount of audio to include before speech starts (in milliseconds).
				/// - Parameter silenceDurationMs: Duration of silence to detect speech stop (in milliseconds).
				/// - Parameter threshold: Activation threshold for VAD (0.0 to 1.0).
				public static func serverVad(createResponse: Bool = true, idleTimeout: Int? = nil, interruptResponse: Bool? = nil, prefixPaddingMs: Int? = nil, silenceDurationMs: Int? = nil, threshold: Double? = nil) -> TurnDetection {
					.init(createResponse: createResponse, eagerness: nil, idleTimeout: idleTimeout, interruptResponse: interruptResponse, prefixPaddingMs: prefixPaddingMs, silenceDurationMs: silenceDurationMs, threshold: threshold, type: .server)
				}

				/// Creates a new `TurnDetection` configuration for Semantic VAD.
				///
				/// - Parameter createResponse: Whether or not to automatically generate a response when a VAD stop event occurs.
				/// - Parameter eagerness: The eagerness of the model to respond.
				/// - Parameter idleTimeout: Optional idle timeout after which turn detection will auto-timeout when no additional audio is received.
				/// - Parameter interruptResponse: Whether or not to automatically interrupt any ongoing response with output to the default conversation when a VAD start event occurs.
				public static func semanticVad(createResponse: Bool = true, eagerness: Eagerness? = .auto, idleTimeout: Int? = nil, interruptResponse: Bool? = nil) -> TurnDetection {
					.init(createResponse: createResponse, eagerness: eagerness, idleTimeout: idleTimeout, interruptResponse: interruptResponse, prefixPaddingMs: nil, silenceDurationMs: nil, threshold: nil, type: .semantic)
				}
			}

			/// The format of input audio.
			public var format: AudioFormat

			/// Configuration for input audio noise reduction.
			///
			/// Noise reduction filters audio added to the input audio buffer before it is sent to VAD and the model.
			///
			/// Filtering the audio can improve VAD and turn detection accuracy (reducing false positives) and model performance by improving perception of the input audio.
			public var noiseReduction: NoiseReduction?

			/// Configuration for input audio transcription.
			///
			/// Input audio transcription is not native to the model, since the model consumes audio directly.
			///
			/// Transcription runs asynchronously through [the `/audio/transcriptions` endpoint](https://platform.openai.com/docs/api-reference/audio/createTranscription) and should be treated as guidance of input audio content rather than precisely what the model heard.
			///
			/// The client can optionally set the language and prompt for transcription, these offer additional guidance to the transcription service.
			public var transcription: Transcription?

			/// Configuration for turn detection, either Server VAD or Semantic VAD.
			///
			/// Server VAD means that the model will detect the start and end of speech based on audio volume and respond at the end of user speech.
			///
			/// Semantic VAD is more advanced and uses a turn detection model (in conjunction with VAD) to semantically estimate whether the user has finished speaking, then dynamically sets a timeout based on this probability.
			///
			/// For example, if user audio trails off with "uhhm", the model will score a low probability of turn end and wait longer for the user to continue speaking.
			///
			/// This can be useful for more natural conversations, but may have a higher latency.
			public var turnDetection: TurnDetection?

			/// Creates a new `Input` configuration.
			///
			/// - Parameter format: The format of input audio.
			/// - Parameter noiseReduction: Configuration for input audio noise reduction.
			/// - Parameter transcription: Configuration for input audio transcription.
			/// - Parameter turnDetection: Configuration for turn detection, either Server VAD or Semantic VAD.
			public init(format: AudioFormat, noiseReduction: NoiseReduction? = nil, transcription: Transcription? = nil, turnDetection: TurnDetection? = nil) {
				self.format = format
				self.transcription = transcription
				self.turnDetection = turnDetection
				self.noiseReduction = noiseReduction
			}
		}

		/// Configuration for output audio.
		public struct Output: Equatable, Hashable, Codable, Sendable {
			/// The voice the model uses to respond.
			///
			/// Voice cannot be changed during the session once the model has responded with audio at least once.
			public var voice: Voice

			/// The speed of the model's spoken response.
			///
			/// `1.0` is the default speed. `0.25` is the minimum speed. `1.5` is the maximum speed.
			///
			/// This value can only be changed in between model turns, not while a response is in progress.
			public var speed: Double

			/// The format of output audio.
			public var format: AudioFormat

			/// Creates a new `Output` configuration.
			///
			/// - Parameter voice: The voice the model uses to respond.
			/// - Parameter speed: The speed of the model's spoken response.
			/// - Parameter format: The format of output audio.
			public init(voice: Voice, speed: Double, format: AudioFormat) {
				self.voice = voice
				self.speed = speed
				self.format = format
			}
		}

		/// Configuration for input audio.
		public var input: Input

		/// Configuration for output audio.
		public var output: Output

		/// Creates a new `Audio` configuration.
		///
		/// - Parameter input: Configuration for input audio.
		/// - Parameter output: Configuration for output audio.
		public init(input: Input, output: Output) {
			self.input = input
			self.output = output
		}
	}

	/// The type of session to create.
	public let type: String = "realtime"

	/// Unique identifier for the session
	public var id: String?

	/// Configuration for input and output audio.
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
	public var toolChoice: Tool.Choice?

	/// Tools available to the model.
	public var tools: [Tool]?

	public init(id: String? = nil, audio: Audio, instructions: String, maxResponseOutputTokens: MaxResponseOutputTokens? = nil, modalities: [Modality]? = nil, model: Model, prompt: Prompt? = nil, temperature: Double? = nil, toolChoice: Tool.Choice? = nil, tools: [Tool]? = nil) {
		self.id = id
		self.tools = tools
		self.model = model
		self.audio = audio
		self.prompt = prompt
		self.toolChoice = toolChoice
		self.modalities = modalities
		self.temperature = temperature
		self.instructions = instructions
		self.maxResponseOutputTokens = maxResponseOutputTokens
	}
}

extension Session.Audio.Input.NoiseReduction: Codable {
	private enum CodingKeys: String, CodingKey {
		case type
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(rawValue, forKey: .type)
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)

		guard let value = Self(rawValue: type) else {
			throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown noise reduction type: \(type)")
		}

		self = value
	}
}
