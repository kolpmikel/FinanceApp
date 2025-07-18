import Foundation

enum TransactionsServiceError: Error {
    case notFound(id: Int)
}

protocol TransactionsServiceProtocol: ObservableObject {
    func todayInterval() -> DateInterval
    
    func getTransactions(of interval: DateInterval) async throws -> [Transaction]
    
    func create(_ tx: Transaction) async throws -> Transaction
    
    func update(_ tx: Transaction) async throws -> Transaction
    
    func delete(id: Int) async throws
}

final class MockTransactionsService: ObservableObject, TransactionsServiceProtocol {
    static let shared = MockTransactionsService()
    
    @Published private var transactions: [Transaction]
    private var nextId: Int
    
    
    private init() {
        _ = Date()
        let initialTransactions: [Transaction] = [
            Transaction(
                id: 1,
                accountId: 1,
                categoryId: 1,
                amount: Decimal(10000.00),
                transactionDate: Date(),
                comment: "тест",
                createdAt: Date(),
                updatedAt: Date()
            ),
            Transaction(
                id: 3,
                accountId: 1,
                categoryId: 3,
                amount: Decimal(10000.00),
                transactionDate: Calendar.current.date(from: DateComponents(year: 2025, month: 7, day: 9, hour: 10, minute: 30))!,
                comment: "Ветеринар",
                createdAt: Date(),
                updatedAt: Date()
            ),
            
        ]
        self.transactions = initialTransactions
        self.nextId = (initialTransactions.map { $0.id }.max() ?? 0) + 1    }
    
    func todayInterval() -> DateInterval {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        return DateInterval(start: startOfDay, end: endOfDay)
    }
    
    func getTransactions(of interval: DateInterval) async throws -> [Transaction] {
        return transactions.filter { interval.contains($0.transactionDate) }
    }
    
    func create(_ tx: Transaction) async throws -> Transaction {
        let now = Date()
        let newTx = Transaction(
            id: nextId,
            accountId: tx.accountId,
            categoryId: tx.categoryId,
            amount: tx.amount,
            transactionDate: tx.transactionDate,
            comment: tx.comment,
            createdAt: now,
            updatedAt: now
        )
        transactions.append(newTx)
        nextId += 1
        return newTx
    }
    
    func update(_ tx: Transaction) async throws -> Transaction {
        guard let idx = transactions.firstIndex(where: { $0.id == tx.id }) else {
            throw TransactionsServiceError.notFound(id: tx.id)
        }
        let now = Date()
        let updated = Transaction(
            id: tx.id,
            accountId: tx.accountId,
            categoryId: tx.categoryId,
            amount: tx.amount,
            transactionDate: tx.transactionDate,
            comment: tx.comment,
            createdAt: transactions[idx].createdAt,
            updatedAt: now
        )
        transactions[idx] = updated
        return updated
    }
    
    func delete(id: Int) async throws {
        guard let idx = transactions.firstIndex(where: { $0.id == id }) else {
            throw TransactionsServiceError.notFound(id: id)
        }
        transactions.remove(at: idx)
    }
}

