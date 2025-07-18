import Foundation

struct Transaction: Identifiable, Codable, Equatable {
    let id: Int
    var accountId: Int?
    var categoryId: Int?
    var amount: Decimal
    var transactionDate: Date
    var comment: String?
    let createdAt: Date
    let updatedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id, accountId, categoryId, amount, transactionDate, comment, createdAt, updatedAt, account, category
    }
    
    init(
        id: Int,
        accountId: Int? = nil,
        categoryId: Int? = nil,
        amount: Decimal,
        transactionDate: Date,
        comment: String? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.accountId = accountId
        self.categoryId = categoryId
        self.amount = amount
        self.transactionDate = transactionDate
        self.comment = comment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try c.decode(Int.self, forKey: .id)
        
        if let acct = try? c.decode(BankAccount.self, forKey: .account) {
            accountId = acct.id
        } else {
            accountId = try? c.decode(Int.self, forKey: .accountId)
        }
        
        if let cat = try? c.decode(Category.self, forKey: .category) {
            categoryId = cat.id
        } else {
            categoryId = try? c.decode(Int.self, forKey: .categoryId)
        }
        
        if let dec = try? c.decode(Decimal.self, forKey: .amount) {
            amount = dec
        } else if let str = try? c.decode(String.self, forKey: .amount),
                  let dec = Decimal(string: str) {
            amount = dec
        } else if let dbl = try? c.decode(Double.self, forKey: .amount) {
            amount = Decimal(dbl)
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .amount, in: c,
                debugDescription: "Неверный формат amount"
            )
        }
        
        self.transactionDate = try c.decode(Date.self, forKey: .transactionDate)
        self.comment = try? c.decode(String.self, forKey: .comment)
        self.createdAt = try c.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try c.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(accountId, forKey: .accountId)
        try c.encodeIfPresent(categoryId, forKey: .categoryId)
        try c.encode(amount, forKey: .amount)
        try c.encode(transactionDate, forKey: .transactionDate)
        try c.encodeIfPresent(comment, forKey: .comment)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
    }
}
