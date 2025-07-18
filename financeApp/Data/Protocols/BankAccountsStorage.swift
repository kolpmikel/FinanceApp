import Foundation

@MainActor
protocol BankAccountsStorageProtocol {
  func fetchPrimary() async throws -> BankAccount
  func update(_ account: BankAccount) async throws
}
