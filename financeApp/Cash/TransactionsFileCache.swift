import Foundation


final class TransactionsFileCache {
    private(set) var transactions: [Transaction] = []
    private let fileName: String

    init(fileName: String = "transactions") {
        self.fileName = fileName
        loadFromFile()
    }

    func fetchAll() throws -> [Transaction] {
        transactions
    }

    func create(_ transaction: Transaction) throws {
        if transactions.contains(where: { $0.id == transaction.id }) {
            throw StorageError.duplicateTransaction
        }
        transactions.append(transaction)
        try saveToFile()
    }

    func update(id: Int, with transaction: Transaction) throws {
        guard let idx = transactions.firstIndex(where: { $0.id == id }) else {
            throw StorageError.transactionNotFound
        }
        transactions[idx] = transaction
        try saveToFile()
    }

    func delete(id: Int) throws {
        guard transactions.contains(where: { $0.id == id }) else {
            throw StorageError.transactionNotFound
        }
        transactions.removeAll { $0.id == id }
        try saveToFile()
    }

    private func saveToFile() throws {
        let objs = transactions.map { $0.jsonObject }
        let data = try JSONSerialization.data(withJSONObject: objs, options: .prettyPrinted)
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw StorageError.fileError
        }
        try data.write(to: dir.appendingPathComponent("\(fileName).json"))
    }

    private func loadFromFile() {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            transactions = []
            return
        }
        let url = dir.appendingPathComponent("\(fileName).json")
        do {
            let data = try Data(contentsOf: url)
            let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            transactions = arr?.compactMap(Transaction.parse) ?? []
        } catch {
            transactions = []
        }
    }

}
