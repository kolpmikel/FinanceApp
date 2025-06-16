enum Direction {
    case income
    case outcome
}

extension Direction: Codable , Equatable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolValue = try? container.decode(Bool.self) {
            self = boolValue ? .income : .outcome
        }
        else if let stringValue = try? container.decode(String.self) {
            switch stringValue.lowercased() {
            case "income": self = .income
            case "outcome": self = .outcome
            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unknown direction “\(stringValue)”"
                )
            }
        } else {
            throw DecodingError.typeMismatch(
                Direction.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Cannot decode Direction"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self == .income)
    }
}
