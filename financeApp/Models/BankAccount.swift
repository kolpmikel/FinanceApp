import Foundation

struct BankAccount: Identifiable, Codable, Equatable {
    let id: Int
    let userId: Int
    let name: String
    var balance: Decimal
    var currency: String
    let createdAt: Date
    let updatedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id
        case userId
        case name
        case balance
        case currency
        case createdAt
        case updatedAt
    }
    
    init(
        id: Int,
        userId: Int,
        name: String,
        balance: Decimal,
        currency: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.balance = balance
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id       = try c.decode(Int.self,    forKey: .id)
        self.userId   = try c.decode(Int.self,    forKey: .userId)
        self.name     = try c.decode(String.self, forKey: .name)
        self.currency = try c.decode(String.self, forKey: .currency)
        
        if let dec = try? c.decode(Decimal.self, forKey: .balance) {
            self.balance = dec
        }
        else if let str = try? c.decode(String.self, forKey: .balance),
                let dec = Decimal(string: str) {
            self.balance = dec
        }
        else {
            let dbl = try c.decode(Double.self, forKey: .balance)
            self.balance = Decimal(dbl)
        }
        
        let iso = ISO8601DateFormatter()
        let createdStr = try c.decode(String.self, forKey: .createdAt)
        guard let cDate = iso.date(from: createdStr) else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt, in: c,
                debugDescription: "Неверный формат даты \(createdStr)"
            )
        }
        self.createdAt = cDate
        
        let updatedStr = try c.decode(String.self, forKey: .updatedAt)
        guard let uDate = iso.date(from: updatedStr) else {
            throw DecodingError.dataCorruptedError(
                forKey: .updatedAt, in: c,
                debugDescription: "Неверный формат даты \(updatedStr)"
            )
        }
        self.updatedAt = uDate
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,       forKey: .id)
        try c.encode(userId,   forKey: .userId)
        try c.encode(name,     forKey: .name)
        try c.encode(currency, forKey: .currency)
        try c.encode(balance,  forKey: .balance)
        
        let iso = ISO8601DateFormatter()
        try c.encode(iso.string(from: createdAt), forKey: .createdAt)
        try c.encode(iso.string(from: updatedAt), forKey: .updatedAt)
    }
}
