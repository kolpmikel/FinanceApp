import Foundation

enum AccountError: Error, LocalizedError {
    case accountNotFound
    
    var errorDescription: String? {
        switch self {
        case .accountNotFound: return "Account not found"
        }
    }
}

protocol BankAccountsServiceProtocol {
    func fetchPrimary() async throws -> BankAccount
    func update(_ account: BankAccount) async throws -> BankAccount
}

final class MockBankAccountsService: ObservableObject, BankAccountsServiceProtocol {
    static let shared = MockBankAccountsService()
    
    @Published private var sampleAccount: [BankAccount] = [
        .init(
            id: 1,
            userId: 1,
            name: "Основной счёт",
            balance: 3336,
            currency: "RUB",
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
    
    init() {}
    
    func fetchPrimary() async throws -> BankAccount {
        guard let acct = sampleAccount.first else {
            throw AccountError.accountNotFound
        }
        return acct
    }
    
    func update(_ account: BankAccount) async throws -> BankAccount {
        guard let idx = sampleAccount.firstIndex(where: { $0.id == account.id }) else {
            throw AccountError.accountNotFound
        }
        sampleAccount[idx] = account
        return account
    }
}
