import Foundation

@MainActor
final class DefaultTransactionsService: TransactionsServiceProtocol {

    @Published private(set) var transactions: [Transaction] = []
    

    private let api: APITransactionsService
    private let storage: SwiftDataTransactionsStorage
    private let backupStorage: BackupStorageProtocol


    init(
        api: APITransactionsService = .shared,
        storage: SwiftDataTransactionsStorage,
        backupStorage: BackupStorageProtocol
    ) {
        self.api = api
        self.storage = storage
        self.backupStorage = backupStorage
    }

    func todayInterval() -> DateInterval {
        Calendar.current.dateInterval(of: .day, for: Date())!
    }

    func getTransactions(of interval: DateInterval) async throws -> [Transaction] {
        let pending = try await backupStorage.fetchAll()
        var syncedIDs = [Int]()
        for item in pending {
            let tx = try item.transaction()
            switch item.action {
            case .create:
                _ = try await api.create(tx)
            case .update:
                _ = try await api.update(tx)
            case .delete:
                try await api.delete(id: tx.id)
            }
            syncedIDs.append(item.id)
        }
        for id in syncedIDs {
            try await backupStorage.remove(id: id)
        }

        do {
            let remote = try await api.getTransactions(of: interval)

            let localAll = try await storage.fetchAll()
            let localIDs = Set(localAll.map(\.id))
            for tx in remote where !localIDs.contains(tx.id) {
                try await storage.create(tx)
            }

            transactions = remote
            return remote
        }
        catch {
            let persisted = try await storage.fetchAll().filter {
                interval.contains($0.transactionDate)
            }
            let backupItems = try await backupStorage.fetchAll()
            let backupTxs = try backupItems.map { try $0.transaction() }
                .filter { interval.contains($0.transactionDate) }

            var merged = persisted
            let existingIDs = Set(merged.map(\.id))
            for tx in backupTxs where !existingIDs.contains(tx.id) {
                merged.append(tx)
            }

            transactions = merged
            return merged
        }
    }

    func create(_ tx: Transaction) async throws -> Transaction {
        let created = try await api.create(tx)
        do {
            try await storage.create(created)
        } catch {
            try await backupStorage.upsert(created, action: .create)
        }
        transactions.append(created)
        return created
    }

    func update(_ tx: Transaction) async throws -> Transaction {
        let updated = try await api.update(tx)
        do {
            try await storage.update(id: updated.id, with: updated)
        } catch {
            try await backupStorage.upsert(updated, action: .update)
        }
        if let idx = transactions.firstIndex(where: { $0.id == updated.id }) {
            transactions[idx] = updated
        }
        return updated
    }

    func delete(id: Int) async throws {
        try await api.delete(id: id)
        do {
            try await storage.delete(id: id)
        } catch {
            try await backupStorage.upsert(
                Transaction(
                    id: id,
                    accountId: nil,
                    categoryId: nil,
                    amount: .zero,
                    transactionDate: Date(),
                    comment: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                action: .delete
            )
        }
        transactions.removeAll { $0.id == id }
    }
}
