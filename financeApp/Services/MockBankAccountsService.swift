import Foundation

final class MockBankAccountsService  {
    private var sampleAccount: [BankAccount] = [
        
        BankAccount(
            id: 1,
            userId: 1,
            name: "Основной счёт",
            balance: 3336,
            currency: "RUB",
            createdAt: Date(),
            updatedAt: Date()
        ),
        BankAccount(
            id: 2,
            userId: 1,
            name: "Запасной счёт",
            balance: 10000,
            currency: "USD",
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
    
    func fetchPrimary() async throws -> BankAccount {
        
        guard let account = sampleAccount.first else {
            throw AccountError.accountNotFound
        }
        return account
    }
    
    func update(_ account: BankAccount) async throws {
        
        guard let index = sampleAccount.firstIndex(where: { $0.id == account.id }) else {
            throw AccountError.accountNotFound
        }
        sampleAccount[index] = account
    }
}



enum AccountError: Error, LocalizedError {
    case accountNotFound
    
    var errorDescription: String? {
        switch self {
        case .accountNotFound: return "Account not found"
        }
    }
}
