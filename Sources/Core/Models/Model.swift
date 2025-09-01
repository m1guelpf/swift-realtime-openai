public enum Model: RawRepresentable, Equatable, Hashable, Codable, Sendable {
	case gptRealtime
	case custom(String)

	public var rawValue: String {
		switch self {
			case .gptRealtime: return "gpt-realtime"
			case let .custom(value): return value
		}
	}

	public init?(rawValue: String) {
		switch rawValue {
			case "gpt-realtime": self = .gptRealtime
			default: self = .custom(rawValue)
		}
	}
}

public extension Model {
	enum Transcription: String, CaseIterable, Equatable, Hashable, Codable, Sendable {
		case whisper = "whisper-1"
		case gpt4o = "gpt-4o-transcribe-latest"
		case gpt4oMini = "gpt-4o-mini-transcribe"
		case gpt4oDiarize = "gpt-4o-transcribe-diarize"
	}
}
