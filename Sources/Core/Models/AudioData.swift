import Foundation

public struct AudioData: Equatable, Hashable, Sendable {
	public var data: Data
}

extension AudioData: Codable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()

		guard let data = try Data(base64Encoded: container.decode(String.self)) else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid base64 string")
		}
		self.data = data
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()

		try container.encode(data.base64EncodedString())
	}
}
