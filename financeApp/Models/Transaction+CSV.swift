import Foundation

extension Transaction {
    static var csvHeader: String {
        ["id",
         "accountId",
         "categoryId",
         "amount",
         "transactionDate",
         "comment",
         "createdAt",
         "updatedAt"
        ].joined(separator: ",")
    }
    
    static func parse(csv: String) -> [Transaction] {
        let lines = csv
            .components(separatedBy: CharacterSet.newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard lines.count > 1 else { return [] }
        let header = lines[0].split(separator: ",").map(String.init)
        
        let iso = ISO8601DateFormatter.fractional
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var result: [Transaction] = []
        
        for line in lines.dropFirst() {
            let values = line.split(separator: ",", omittingEmptySubsequences: false)
                .map(String.init)
            guard values.count == header.count else { continue }
            
            var dict: [String: String] = [:]
            for (i, key) in header.enumerated() {
                dict[key] = values[i]
            }
            
            guard
                let id       = Int(dict["id"] ?? ""),
                let acctId   = Int(dict["accountId"] ?? ""),
                let catId    = Int(dict["categoryId"] ?? ""),
                let amount   = Decimal(string: dict["amount"] ?? ""),
                let txDate   = iso.date(from: dict["transactionDate"] ?? "")
            else {
                continue
            }
            
            let comment   = dict["comment"]?.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            let createdAt = iso.date(from: dict["createdAt"] ?? "") ?? Date()
            let updatedAt = iso.date(from: dict["updatedAt"] ?? "") ?? Date()
            
            result.append(
                Transaction(
                    id: id,
                    accountId: acctId,
                    categoryId: catId,
                    amount: amount,
                    transactionDate: txDate,
                    comment: comment,
                    createdAt: createdAt,
                    updatedAt: updatedAt
                )
            )
        }
        
        return result
    }
    
    var csvLine: String {
        let iso = ISO8601DateFormatter.fractional
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let idStr      = String(id)
        let acctIdStr  = String(accountId ?? 0)
        let catIdStr   = String(categoryId ?? 0)
        let amountStr  = NSDecimalNumber(decimal: amount).stringValue
        let txDateStr  = iso.string(from: transactionDate)
        let commentRaw = comment?.replacingOccurrences(of: "\"", with: "'") ?? ""
        let commentStr = commentRaw.contains(",") ? "\"\(commentRaw)\"" : commentRaw
        let createdStr = iso.string(from: createdAt)
        let updatedStr = iso.string(from: updatedAt)
        
        return [
            idStr, acctIdStr, catIdStr,
            amountStr, txDateStr,
            commentStr,
            createdStr, updatedStr
        ].joined(separator: ",")
    }
}
