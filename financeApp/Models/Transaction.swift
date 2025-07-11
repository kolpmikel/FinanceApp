import Foundation

struct Transaction: Identifiable, Codable, Equatable {
    let id: Int
    
    let accountId: Int?
    var categoryId: Int?
    
    let account: BankAccount?
    let category: Category?
    
    var amount: Decimal
    var transactionDate: Date
    var comment: String?
    
    let createdAt: Date
    let updatedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id
        case accountId
        case categoryId
        case account
        case category
        case amount
        case transactionDate
        case comment
        case createdAt
        case updatedAt
    }
    
    init(
        id: Int,
        accountId: Int? = nil,
        categoryId: Int? = nil,
        account: BankAccount? = nil,
        category: Category? = nil,
        amount: Decimal,
        transactionDate: Date,
        comment: String? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.accountId = accountId
        self.categoryId = categoryId
        self.account = account
        self.category = category
        self.amount = amount
        self.transactionDate = transactionDate
        self.comment = comment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(Int.self, forKey: .id)
        
        if let acct = try? container.decode(BankAccount.self, forKey: .account) {
            self.account = acct
            self.accountId = acct.id
        } else {
            self.account = nil
            self.accountId = try? container.decode(Int.self, forKey: .accountId)
        }
        
        if let cat = try? container.decode(Category.self, forKey: .category) {
            self.category = cat
            self.categoryId = cat.id
        } else {
            self.category = nil
            self.categoryId = try? container.decode(Int.self, forKey: .categoryId)
        }
        
        if let dec = try? container.decode(Decimal.self, forKey: .amount) {
            self.amount = dec
        }
        else if let str = try? container.decode(String.self, forKey: .amount),
                let dec = Decimal(string: str) {
            self.amount = dec
        }
        else {
            let dbl = try container.decode(Double.self, forKey: .amount)
            self.amount = Decimal(dbl)
        }
        
        let iso = ISO8601DateFormatter()
        let txDateStr  = try container.decode(String.self, forKey: .transactionDate)
        guard let txDate = iso.date(from: txDateStr) else {
            throw DecodingError.dataCorruptedError(
                forKey: .transactionDate, in: container,
                debugDescription: "Невалидная дата \(txDateStr)"
            )
        }
        self.transactionDate = txDate
        
        let createdStr = try container.decode(String.self, forKey: .createdAt)
        guard let cDate = iso.date(from: createdStr) else {
            throw DecodingError.dataCorruptedError(
                forKey: .createdAt, in: container,
                debugDescription: "Невалидная дата \(createdStr)"
            )
        }
        self.createdAt = cDate
        
        let updatedStr = try container.decode(String.self, forKey: .updatedAt)
        guard let uDate = iso.date(from: updatedStr) else {
            throw DecodingError.dataCorruptedError(
                forKey: .updatedAt, in: container,
                debugDescription: "Невалидная дата \(updatedStr)"
            )
        }
        self.updatedAt = uDate
        
        self.comment = try? container.decode(String.self, forKey: .comment)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        if let accountId = accountId {
            try container.encode(accountId, forKey: .accountId)
        }
        if let categoryId = categoryId {
            try container.encode(categoryId, forKey: .categoryId)
        }
        
        try container.encodeIfPresent(comment, forKey: .comment)
        
        try container.encode(amount, forKey: .amount)
        
        let iso = ISO8601DateFormatter()
        try container.encode(iso.string(from: transactionDate), forKey: .transactionDate)
        try container.encode(iso.string(from: createdAt), forKey: .createdAt)
        try container.encode(iso.string(from: updatedAt), forKey: .updatedAt)
    }
}
