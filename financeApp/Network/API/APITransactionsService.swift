import Foundation


final class APITransactionsService: TransactionsServiceProtocol {
    static let shared = APITransactionsService()
    private init() {}
    
    private let accountService: any BankAccountsServiceProtocol = APIBankAccountsService.shared
    
    func todayInterval() -> DateInterval {
        Calendar.current.dateInterval(of: .day, for: Date())!
    }
    
    func getTransactions(of interval: DateInterval) async throws -> [Transaction] {

        let account = try await accountService.fetchPrimary()
        
        let iso   = ISO8601DateFormatter.fractional
        let start = iso.string(from: interval.start)
        let end   = iso.string(from: interval.end)
        
        let path = "transactions/account/\(account.id)/period"
        + "?start_date=\(start)&end_date=\(end)"
        
        return try await NetworkClient.shared.request(
            path:   path,
            method: .GET,
            body:   EmptyBody()
        )
        
    }
    
    func create(_ tx: Transaction) async throws -> Transaction {
        return try await NetworkClient.shared.request(
            path:   "transactions",
            method: .POST,
            body:   tx
        )
    }
    
    func update(_ tx: Transaction) async throws -> Transaction {
        return try await NetworkClient.shared.request(
            path:   "transactions/\(tx.id)",
            method: .PUT,
            body:   tx
        )
    }
    
    func delete(id: Int) async throws {
        _ = try await NetworkClient.shared.request(
            path:   "transactions/\(id)",
            method: .DELETE,
            body:   EmptyBody()
        ) as EmptyResponse
    }
}
