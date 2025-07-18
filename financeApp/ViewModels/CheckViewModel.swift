import Foundation

@MainActor
class CheckViewModel: ObservableObject {
    private let service: any BankAccountsServiceProtocol
    
    @Published var bankAccount: BankAccount? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    init(service: any BankAccountsServiceProtocol = APIBankAccountsService.shared) {
        self.service = service
    }
    
    func loadAccount() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let acct = try await service.fetchPrimary()
            bankAccount = acct
        } catch {
            errorMessage = makeUserMessage(from: error)
        }
    }
    
    func updateAccount(name: String, balance: Decimal, currency: String) async {
        guard var acct = bankAccount else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        acct.name     = name
        acct.balance  = balance
        acct.currency = currency
        
        do {
            let updated = try await service.update(acct)
            bankAccount = updated
        } catch {
            errorMessage = makeUserMessage(from: error)
        }
    }
}
