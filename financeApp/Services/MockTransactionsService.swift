import Foundation

enum TransactionsServiceError: Error {
    case notFound(id: Int)
}

final class MockTransactionsService:  ObservableObject {
    
    
    @Published private var mockTransactions: [Transaction] = [
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
            id: 1,
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
            transactionDate: Calendar.current.date(from: DateComponents(year: 2025, month: 6, day: 15, hour: 10, minute: 30))!,
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
    
    
    private var transactions: [Transaction]
    private var nextId: Int
    
    init(initial: [Transaction] = []) {
        self.transactions = initial
        self.nextId = (initial.map { $0.id }.max() ?? 0) + 1
    }
    
    func todayInterval() -> DateInterval {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        return DateInterval(start: startOfDay, end: endOfDay)
    }
    
    func getTransactionsOfPeriod(interval: DateInterval) async throws -> [Transaction] {
        
        return mockTransactions.filter { transaction in
            interval.contains(transaction.transactionDate)
        }
    }
    
    func create(_ transaction: Transaction) async throws -> Transaction {
        let now = Date()
        let newTx = Transaction(
            id: nextId,
            accountId: transaction.accountId,
            categoryId: transaction.categoryId,
            account: transaction.account,
            category: transaction.category,
            amount: transaction.amount,
            transactionDate: transaction.transactionDate,
            comment: transaction.comment,
            createdAt: now,
            updatedAt: now
        )
        transactions.append(newTx)
        nextId += 1
        return newTx
    }
    
    func update(_ transaction: Transaction) async throws -> Transaction {
        guard let index = transactions.firstIndex(where: { $0.id == transaction.id }) else {
            throw TransactionsServiceError.notFound(id: transaction.id)
        }
        let now = Date()
        let updatedTx = Transaction(
            id: transaction.id,
            accountId: transaction.accountId,
            categoryId: transaction.categoryId,
            account: transaction.account,
            category: transaction.category,
            amount: transaction.amount,
            transactionDate: transaction.transactionDate,
            comment: transaction.comment,
            createdAt: transactions[index].createdAt,
            updatedAt: now
        )
        transactions[index] = updatedTx
        return updatedTx
    }
    
    func delete(id: Int) async throws {
        guard transactions.contains(where: { $0.id == id }) else {
            throw TransactionsServiceError.notFound(id: id)
        }
        transactions.removeAll { $0.id == id }
    }
}
