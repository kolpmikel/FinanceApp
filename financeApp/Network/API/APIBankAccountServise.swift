import Foundation


final class APIBankAccountsService: BankAccountsServiceProtocol {
    static let shared = APIBankAccountsService()
    private init() {}
    
    func fetchPrimary() async throws -> BankAccount {
        let all: [BankAccount] = try await NetworkClient.shared.request(
            path:   "accounts",
            method: .GET,
            body:   EmptyBody()
        )
        guard let first = all.first else {
            throw NetworkError.badStatus(code: 404, data: Data())
        }
        return first
    }
    
    func update(_ account: BankAccount) async throws -> BankAccount {
        return try await NetworkClient.shared.request(
            path:   "accounts/\(account.id)",
            method: .PUT,
            body:   account
        )
    }
}
