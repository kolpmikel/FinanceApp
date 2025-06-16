import Foundation

extension Transaction {
    static var csvHeader: String {
        return [
            "id",
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
        guard lines.count > 1 else {
            return []
        }

        let headerColumns = lines[0].split(separator: ",").map { String($0) }
        let isoFormatter = ISO8601DateFormatter()
        var result: [Transaction] = []

        for line in lines.dropFirst() {
            let values = line
                .split(separator: ",", omittingEmptySubsequences: false)
                .map { String($0) }
            guard values.count == headerColumns.count else {
                continue
            }
            var dict: [String: String] = [:]
            for (index, key) in headerColumns.enumerated() {
                dict[key] = values[index]
            }
            guard
                let id        = Int(dict["id"] ?? ""),
                let acctId    = Int(dict["accountId"] ?? ""),
                let catId     = Int(dict["categoryId"] ?? ""),
                let amount    = Decimal(string: dict["amount"] ?? ""),
                let txDate    = isoFormatter.date(from: dict["transactionDate"] ?? "")
            else {
                continue
            }
            let comment    = dict["comment"]
            let createdAt  = isoFormatter.date(from: dict["createdAt"] ?? "") ?? Date()
            let updatedAt  = isoFormatter.date(from: dict["updatedAt"] ?? "") ?? Date()

            let tx = Transaction(
                id: id,
                accountId: acctId,
                categoryId: catId,
                account: nil,
                category: nil,
                amount: amount,
                transactionDate: txDate,
                comment: comment,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
            result.append(tx)
        }
        return result
    }

    var csvLine: String {
        let isoFormatter = ISO8601DateFormatter()
        let idStr       = String(id)
        let acctIdStr   = String(accountId ?? 0)
        let catIdStr    = String(categoryId ?? 0)
        let amountStr   = NSDecimalNumber(decimal: amount).stringValue
        let txDateStr   = isoFormatter.string(from: transactionDate)
        let commentStr  = comment?.replacingOccurrences(of: "\n", with: " ") ?? ""
        let createdStr  = isoFormatter.string(from: createdAt)
        let updatedStr  = isoFormatter.string(from: updatedAt)

        let escapedComment = commentStr.contains(",") ? "\"\(commentStr)\"" : commentStr
        
        return [
            idStr,
            acctIdStr,
            catIdStr,
            amountStr,
            txDateStr,
            escapedComment,
            createdStr,
            updatedStr
        ].joined(separator: ",")
    }
}
