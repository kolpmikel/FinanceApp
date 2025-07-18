import Foundation
import SwiftData

@MainActor
final class SwiftDataTransactionsStorage: TransactionsStorage {
    let container: ModelContainer

    var modelContext: ModelContext { container.mainContext }

    private let categoriesService: APICategoriesService

    init(
        categoriesService: APICategoriesService = APICategoriesService()
    ) throws {
        self.container = try ModelContainer(for: SDTransaction.self)
        self.categoriesService = categoriesService
    }

    func fetchAll() async throws -> [Transaction] {
        let sdItems: [SDTransaction] = try modelContext.fetch(
            FetchDescriptor<SDTransaction>(
                predicate: nil,
                sortBy: [ SortDescriptor(\.date) ]
            )
        )

        let cats: [Category]
        do {
            cats = try await categoriesService.fetchAll()
        } catch {
            throw StorageError.networkError(error)
        }

        return sdItems.map { sd in
            Transaction(
                id: sd.id,
                accountId: nil,
                categoryId: sd.categoryID,
                amount: Decimal(sd.amount),
                transactionDate: sd.date,
                comment: nil,
                createdAt: sd.date,
                updatedAt: sd.date
            )
        }
    }

    func create(_ transaction: Transaction) async throws {
        let existing: [SDTransaction] = try modelContext.fetch(
            FetchDescriptor<SDTransaction>(
                predicate: #Predicate { $0.id == transaction.id }
            )
        )
        guard existing.isEmpty else {
            throw StorageError.duplicateTransaction
        }

        let sd = SDTransaction(
            id: transaction.id,
            date: transaction.transactionDate,
            amount: NSDecimalNumber(decimal: transaction.amount).doubleValue,
            categoryID: transaction.categoryId ?? 0,
            directionRaw: ""
        )
        modelContext.insert(sd)
        try modelContext.save()
    }

    func update(id: Int, with transaction: Transaction) async throws {
        let found: [SDTransaction] = try modelContext.fetch(
            FetchDescriptor<SDTransaction>(
                predicate: #Predicate { $0.id == id }
            )
        )
        guard let sd = found.first else {
            throw StorageError.transactionNotFound
        }

        sd.date         = transaction.transactionDate
        sd.amount       = NSDecimalNumber(decimal: transaction.amount).doubleValue
        sd.categoryID   = transaction.categoryId ?? sd.categoryID
        sd.directionRaw = ""
        try modelContext.save()
    }

    func delete(id: Int) async throws {
        let found: [SDTransaction] = try modelContext.fetch(
            FetchDescriptor<SDTransaction>(
                predicate: #Predicate { $0.id == id }
            )
        )
        guard let sd = found.first else {
            throw StorageError.transactionNotFound
        }
        modelContext.delete(sd)
        try modelContext.save()
    }
}
