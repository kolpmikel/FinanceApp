import Foundation

@MainActor
protocol TransactionsStorage {
    func fetchAll() async throws -> [Transaction]
    func create(_ transaction: Transaction) async throws
    func update(id: Int, with transaction: Transaction) async throws
    func delete(id: Int) async throws
}

enum StorageError: Error {
    case duplicateTransaction
    case transactionNotFound
    case networkError(Error)
    case fileError
}
