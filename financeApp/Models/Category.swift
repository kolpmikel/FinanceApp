import Foundation


struct Category: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let emoji: Character
    let direction: Direction

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case emoji
        case isIncome
    }

    init(
        id: Int,
        name: String,
        emoji: Character,
        direction: Direction
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.direction = direction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)

        self.name = try container.decode(String.self, forKey: .name)

        let emojiString = try container.decode(String.self, forKey: .emoji)
        guard let ch = emojiString.first else {
            throw DecodingError.dataCorruptedError(
                forKey: .emoji,
                in: container,
                debugDescription: "Emoji string is empty"
            )
        }
        self.emoji = ch

        let isIncome = try container.decode(Bool.self, forKey: .isIncome)
        self.direction = isIncome ? .income : .outcome
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id,       forKey: .id)
        try container.encode(name,     forKey: .name)
        try container.encode(String(emoji), forKey: .emoji)
        try container.encode(direction == .income, forKey: .isIncome)
    }
}
