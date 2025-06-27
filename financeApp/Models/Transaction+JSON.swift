import Foundation

extension Transaction {
    static func parse(jsonObject: Any) -> Transaction? {
        guard let dict = jsonObject as? [String: Any] else { return nil }
        
        guard let id = dict["id"] as? Int else { return nil }
        
        let accountId  = dict["accountId"]  as? Int
        let categoryId = dict["categoryId"] as? Int
        
        let amount: Decimal
        if let str = dict["amount"] as? String, let dec = Decimal(string: str) {
            amount = dec
        }
        else if let num = dict["amount"] as? NSNumber {
            amount = num.decimalValue
        }
        else {
            return nil
        }
        
        
        let iso = ISO8601DateFormatter()
        guard
            let txDateStr = dict["transactionDate"] as? String,
            let txDate    = iso.date(from: txDateStr),
            let createdStr = dict["createdAt"] as? String,
            let createdAt  = iso.date(from: createdStr),
            let updatedStr = dict["updatedAt"] as? String,
            let updatedAt  = iso.date(from: updatedStr)
        else {
            return nil
        }
        
        let comment = dict["comment"] as? String
        
        return Transaction(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            account: nil,
            category: nil,
            amount: amount,
            transactionDate: txDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    var jsonObject: Any {
        var dict: [String: Any] = [
            "id":               id,
            "accountId":        accountId as Any,
            "categoryId":       categoryId as Any,
            "amount":           NSDecimalNumber(decimal: amount),
            "transactionDate":  ISO8601DateFormatter().string(from: transactionDate),
            "createdAt":        ISO8601DateFormatter().string(from: createdAt),
            "updatedAt":        ISO8601DateFormatter().string(from: updatedAt)
        ]
        if let comment = comment {
            dict["comment"] = comment
        }
        return dict
    }
}
