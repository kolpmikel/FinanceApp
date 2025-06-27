import Foundation
import SwiftUI

class CheckViewModel: ObservableObject {
    private let bankAccountService = MockBankAccountsService()
    
    @Published var bankAccount: BankAccount? = nil
    @Published var errorMessage: String? = nil
    
    @MainActor
    func loadAccount() async {
        do {
            let bankAccount = try await bankAccountService.fetchPrimary()
            self.bankAccount = bankAccount
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
}
