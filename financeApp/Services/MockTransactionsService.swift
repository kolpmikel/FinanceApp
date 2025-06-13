import Foundation

protocol TransactionsServiceProtocol {

    func fetch(start: Date, end: Date) async throws -> [Transaction]


    func create(_ transaction: Transaction) async throws -> Transaction


    func update(_ transaction: Transaction) async throws -> Transaction


    func delete(id: Int) async throws
}

enum TransactionsServiceError: Error {
    case notFound(id: Int)
}

final class MockTransactionsService: TransactionsServiceProtocol {
    private var transactions: [Transaction]
    private var nextId: Int

    init(initial: [Transaction] = []) {
        self.transactions = initial
        self.nextId = (initial.map { $0.id }.max() ?? 0) + 1
    }

    func fetch(start: Date, end: Date) async throws -> [Transaction] {
        return transactions.filter { tx in
            tx.transactionDate >= start && tx.transactionDate <= end
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
