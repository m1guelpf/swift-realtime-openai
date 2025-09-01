/// Represents a JSON Schema for validating JSON data structures.
public indirect enum JSONSchema: Equatable, Hashable, Sendable {
	/// Represents the format of a string in JSON Schema.
	public enum StringFormat: String, Codable, Hashable, Equatable, Sendable {
		case ipv4, ipv6, uuid, date, time, email, duration, hostname, dateTime = "date-time"
	}

	case null(description: String? = nil)
	case boolean(description: String? = nil)
	case anyOf([JSONSchema], description: String? = nil)
	case `enum`(cases: [String], description: String? = nil)
	case object(properties: [String: JSONSchema], description: String? = nil)
	case string(pattern: String? = nil, format: StringFormat? = nil, description: String? = nil)
	case array(of: JSONSchema, minItems: Int? = nil, maxItems: Int? = nil, description: String? = nil)
	case number(
		multipleOf: Int? = nil,
		minimum: Int? = nil,
		exclusiveMinimum: Int? = nil,
		maximum: Int? = nil,
		exclusiveMaximum: Int? = nil,
		description: String? = nil
	)
	case integer(
		multipleOf: Int? = nil,
		minimum: Int? = nil,
		exclusiveMinimum: Int? = nil,
		maximum: Int? = nil,
		exclusiveMaximum: Int? = nil,
		description: String? = nil
	)

	var description: String? {
		switch self {
			case let .null(description),
			     let .boolean(description),
			     let .anyOf(_, description),
			     let .enum(_, description),
			     let .object(_, description),
			     let .string(_, _, description),
			     let .array(_, _, _, description),
			     let .number(_, _, _, _, _, description),
			     let .integer(_, _, _, _, _, description): return description
		}
	}

	func withDescription(_: String?) -> JSONSchema {
		switch self {
			case .null: return .null(description: description)
			case .boolean: return .boolean(description: description)
			case let .anyOf(cases, _): return .anyOf(cases, description: description)
			case let .enum(cases, _): return .enum(cases: cases, description: description)
			case let .object(properties, _): return .object(properties: properties, description: description)
			case let .string(pattern, format, _): return .string(pattern: pattern, format: format, description: description)
			case let .array(of: items, minItems, maxItems, _):
				return .array(of: items, minItems: minItems, maxItems: maxItems, description: description)
			case let .number(multipleOf, maximum, exclusiveMaximum, minimum, exclusiveMinimum, _):
				return .number(
					multipleOf: multipleOf, minimum: minimum, exclusiveMinimum: exclusiveMinimum,
					maximum: maximum, exclusiveMaximum: exclusiveMaximum, description: description
				)
			case let .integer(multipleOf, maximum, exclusiveMaximum, minimum, exclusiveMinimum, _):
				return .integer(
					multipleOf: multipleOf, minimum: minimum, exclusiveMinimum: exclusiveMinimum,
					maximum: maximum, exclusiveMaximum: exclusiveMaximum, description: description
				)
		}
	}
}

extension JSONSchema: Codable {
	private enum CodingKeys: String, CodingKey {
		case type, items, `enum`, anyOf, format, pattern, required, minItems, maxItems, minimum, maximum,
		     properties, multipleOf, description, exclusiveMinimum, exclusiveMaximum, additionalProperties
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
			case let .null(description):
				try container.encode("null", forKey: .type)
				if let description = description { try container.encode(description, forKey: .description) }
			case let .boolean(description):
				try container.encode("boolean", forKey: .type)
				if let description = description { try container.encode(description, forKey: .description) }
			case let .anyOf(cases, description):
				try container.encode(cases, forKey: .anyOf)
				if let description = description { try container.encode(description, forKey: .description) }
			case let .enum(cases, description):
				try container.encode(cases, forKey: .enum)
				try container.encode("string", forKey: .type)
				if let description { try container.encode(description, forKey: .description) }
			case let .object(properties, description):
				try container.encode("object", forKey: .type)
				try container.encode(properties, forKey: .properties)
				try container.encode(false, forKey: .additionalProperties)
				try container.encode(Array(properties.keys), forKey: .required)
				if let description { try container.encode(description, forKey: .description) }
			case let .string(pattern, format, description):
				try container.encode("string", forKey: .type)
				if let pattern = pattern { try container.encode(pattern, forKey: .pattern) }
				if let description { try container.encode(description, forKey: .description) }
				if let format = format { try container.encode(format.rawValue, forKey: .format) }
			case let .array(of: items, minItems, maxItems, description):
				try container.encode(items, forKey: .items)
				try container.encode("array", forKey: .type)
				if let description { try container.encode(description, forKey: .description) }
				if let minItems = minItems { try container.encode(minItems, forKey: .minItems) }
				if let maxItems = maxItems { try container.encode(maxItems, forKey: .maxItems) }
			case let .number(multipleOf, maximum, exclusiveMaximum, minimum, exclusiveMinimum, description):
				try container.encode("number", forKey: .type)
				if let minimum = minimum { try container.encode(minimum, forKey: .minimum) }
				if let maximum = maximum { try container.encode(maximum, forKey: .maximum) }
				if let description { try container.encode(description, forKey: .description) }
				if let multipleOf = multipleOf { try container.encode(multipleOf, forKey: .multipleOf) }
				if let exclusiveMaximum = exclusiveMaximum { try container.encode(exclusiveMaximum, forKey: .exclusiveMaximum) }
				if let exclusiveMinimum = exclusiveMinimum { try container.encode(exclusiveMinimum, forKey: .exclusiveMinimum) }
			case let .integer(multipleOf, maximum, exclusiveMaximum, minimum, exclusiveMinimum, description):
				try container.encode("integer", forKey: .type)
				if let minimum = minimum { try container.encode(minimum, forKey: .minimum) }
				if let maximum = maximum { try container.encode(maximum, forKey: .maximum) }
				if let description { try container.encode(description, forKey: .description) }
				if let multipleOf = multipleOf { try container.encode(multipleOf, forKey: .multipleOf) }
				if let exclusiveMaximum = exclusiveMaximum { try container.encode(exclusiveMaximum, forKey: .exclusiveMaximum) }
				if let exclusiveMinimum = exclusiveMinimum { try container.encode(exclusiveMinimum, forKey: .exclusiveMinimum) }
		}
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let description = try container.decodeIfPresent(String.self, forKey: .description)

		if let anyOf = try container.decodeIfPresent([JSONSchema].self, forKey: .anyOf) {
			self = .anyOf(anyOf, description: description)
			return
		}

		let type = try container.decode(String.self, forKey: .type)

		if type == "null" {
			self = .null(description: description)
			return
		}

		if type == "boolean" {
			self = .boolean(description: description)
			return
		}

		if type == "object" {
			self = try .object(
				properties: container.decode([String: JSONSchema].self, forKey: .properties),
				description: description
			)
			return
		}

		if type == "string", let enumCases = try container.decodeIfPresent([String].self, forKey: .enum) {
			self = .enum(cases: enumCases, description: description)
			return
		}

		if type == "string" {
			self = try .string(
				pattern: container.decodeIfPresent(String.self, forKey: .pattern),
				format: container.decodeIfPresent(StringFormat.self, forKey: .format),
				description: description
			)
			return
		}

		if type == "array" {
			self = try .array(
				of: container.decode(JSONSchema.self, forKey: .items),
				minItems: container.decodeIfPresent(Int.self, forKey: .minItems),
				maxItems: container.decodeIfPresent(Int.self, forKey: .maxItems),
				description: description
			)
			return
		}

		if type == "number" {
			self = try .number(
				multipleOf: container.decodeIfPresent(Int.self, forKey: .multipleOf),
				minimum: container.decodeIfPresent(Int.self, forKey: .minimum),
				exclusiveMinimum: container.decodeIfPresent(Int.self, forKey: .exclusiveMinimum),
				maximum: container.decodeIfPresent(Int.self, forKey: .maximum),
				exclusiveMaximum: container.decodeIfPresent(Int.self, forKey: .exclusiveMaximum),
				description: description
			)
			return
		}

		if type == "integer" {
			self = try .integer(
				multipleOf: container.decodeIfPresent(Int.self, forKey: .multipleOf),
				minimum: container.decodeIfPresent(Int.self, forKey: .minimum),
				exclusiveMinimum: container.decodeIfPresent(Int.self, forKey: .exclusiveMinimum),
				maximum: container.decodeIfPresent(Int.self, forKey: .maximum),
				exclusiveMaximum: container.decodeIfPresent(Int.self, forKey: .exclusiveMaximum),
				description: description
			)
			return
		}

		throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unsupported schema type")
	}
}
