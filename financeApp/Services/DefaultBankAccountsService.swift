import Foundation

@MainActor
final class DefaultBankAccountsService: BankAccountsServiceProtocol {
    private let api: APIBankAccountsService
    private let storage: BankAccountsStorageProtocol
    private let backupStorage: BackupStorageProtocol

    init(
        api: APIBankAccountsService = .shared,
        storage: BankAccountsStorageProtocol,
        backupStorage: BackupStorageProtocol
    ) {
        self.api = api
        self.storage = storage
        self.backupStorage = backupStorage
    }

    func fetchPrimary() async throws -> BankAccount {
        do {
            return try await storage.fetchPrimary()
        } catch {
            let remote = try await api.fetchPrimary()
            try await storage.update(remote)
            try await backupStorage.remove(id: remote.id)
            return remote
        }
    }

    func update(_ account: BankAccount) async throws -> BankAccount {
        let updated = try await api.update(account)
        do {
            try await storage.update(updated)
            try await backupStorage.remove(id: updated.id)
        } catch {
            let tx = updated.toBalanceTransaction()
            try await backupStorage.upsert(tx, action: .update)
        }
        return updated
    }
}
