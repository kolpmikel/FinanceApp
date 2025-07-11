import Foundation

enum TransactionsServiceError: Error {
    case notFound(id: Int)
}

final class MockTransactionsService: ObservableObject {
    static let shared = MockTransactionsService()
    
    @Published private var transactions: [Transaction]
    private var nextId: Int
    
    private init() {
        let now = Date()
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
                id: 8,
                accountId: 1,
                categoryId: 3,
                amount: Decimal(2000.00),
                transactionDate: Date(),
                comment: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            Transaction(
                id: 2,
                accountId: 1,
                categoryId: 5,
                amount: Decimal(3000.00),
                transactionDate: Date(),
                comment: "Кофе",
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
            Transaction(
                id: 4,
                accountId: 1,
                categoryId: 1,
                amount: Decimal(5000.00),
                transactionDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                comment: "Абонемент",
                createdAt: Date(),
                updatedAt: Date()
            ),
            Transaction(
                id: 5,
                accountId: 1,
                categoryId: 2,
                amount: Decimal(1000.00),
                transactionDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                comment: "Танцы",
                createdAt: Date(),
                updatedAt: Date()
            ),
            Transaction(
                id: 6,
                accountId: 1,
                categoryId: 4,
                amount: Decimal(100.00),
                transactionDate: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
                comment: "Учеба",
                createdAt: Date(),
                updatedAt: Date()
            ),
            Transaction(
                id: 7,
                accountId: 1,
                categoryId: 4,
                amount: Decimal(500.00),
                transactionDate: Calendar.current.date(byAdding: .day, value: -17, to: Date()) ?? Date(),
                comment: "Учеба",
                createdAt: Date(),
                updatedAt: Date()
            )
            
        ]
        self.transactions = initialTransactions
        self.nextId = (initialTransactions.map { $0.id }.max() ?? 0) + 1    }
    
    func todayInterval() -> DateInterval {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        return DateInterval(start: startOfDay, end: endOfDay)
    }
    
    func getTransactionsOfPeriod(interval: DateInterval) async throws -> [Transaction] {
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
