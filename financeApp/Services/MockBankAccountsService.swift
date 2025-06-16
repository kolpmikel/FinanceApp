import Foundation

protocol BankAccountsServiceProtocol {
    func fetchPrimary() async throws -> BankAccount
    func update(account: BankAccount) async throws -> BankAccount
}

final class MockBankAccountsService: BankAccountsServiceProtocol {
    private var sampleAccount = BankAccount(
        id: 1,
        userId: 42,
        name: "Основной счёт",
        balance: Decimal(string: "12345.67") ?? 0,
        currency: "EUR",
        createdAt: Date(timeIntervalSince1970: 1_600_000_000),
        updatedAt: Date(timeIntervalSince1970: 1_650_000_000)
    )

    func fetchPrimary() async throws -> BankAccount {
       
        return sampleAccount
    }

    func update(account: BankAccount) async throws -> BankAccount {
        sampleAccount = BankAccount(
            id: account.id,
            userId: account.userId,
            name: account.name,
            balance: account.balance,
            currency: account.currency,
            createdAt: sampleAccount.createdAt,
            updatedAt: Date()
        )
        return sampleAccount
    }
}
