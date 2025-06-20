import Foundation
final class TransactionsFileCache {
    private let fileName: String
    private let fileURL: URL

    private var transactions: [Transaction] = []

    var allTransactions: [Transaction] {
        return transactions
    }

    init(fileName: String = "transactions.json") {
        self.fileName = fileName
        let fm = FileManager.default

        guard let supportDir = fm.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            fatalError("Не удалось найти Application Support directory")
        }

        if !fm.fileExists(atPath: supportDir.path) {
            do {
                try fm.createDirectory(
                    at: supportDir,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                fatalError("Не удалось создать Application Support directory: \(error)")
            }
        }

        self.fileURL = supportDir.appendingPathComponent(fileName)
        _ = load()
    }

    func add(_ transaction: Transaction) {
        guard !transactions.contains(where: { $0.id == transaction.id }) else {
            return
        }
        transactions.append(transaction)
    }

    func remove(id: Int) {
        transactions.removeAll(where: { $0.id == id })
    }

    func save() throws {
        let jsonArray = transactions.map { $0.jsonObject }
        guard JSONSerialization.isValidJSONObject(jsonArray) else {
            throw NSError(domain: "TransactionsFileCache", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid JSON "]) }
        let data = try JSONSerialization.data(withJSONObject: jsonArray, options: [.prettyPrinted])
        try data.write(to: fileURL, options: [.atomic])
    }
    
//    enum error:Error, CustomNSError{
//        case fileCache
//    }
//
    
    func load() -> [Transaction] {
        transactions.removeAll()
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return transactions
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let raw = try JSONSerialization.jsonObject(with: data, options: [])
            guard let array = raw as? [Any] else {
                return transactions
            }
            let parsed = array.compactMap { Transaction.parse(jsonObject: $0) }
            var unique: [Int: Transaction] = [:]
            for tx in parsed {
                unique[tx.id] = tx
            }
            transactions = Array(unique.values)
        } catch {
            transactions.removeAll()
        }
        return transactions
    }
}
