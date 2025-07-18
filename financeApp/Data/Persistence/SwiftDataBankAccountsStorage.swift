import Foundation
import SwiftData

@MainActor
final class SwiftDataBankAccountsStorage: BankAccountsStorageProtocol {
  private let context: ModelContext
  private let backup: BackupStorageProtocol

  init(context: ModelContext, backup: BackupStorageProtocol) {
    self.context = context
    self.backup = backup
  }

  func fetchPrimary() async throws -> BankAccount {
    let allSD: [SDBankAccount] = try context.fetch(
      FetchDescriptor<SDBankAccount>(predicate: nil)
    )
    if let sd = allSD.first {
      return BankAccount(
        id:        sd.id,
        userId:    sd.userId,
        name:      sd.name,
        balance:   Decimal(sd.balance),
        currency:  sd.currency,
        createdAt: sd.createdAt,
        updatedAt: sd.updatedAt
      )
    }

    throw StorageError.transactionNotFound
  }

  func update(_ account: BankAccount) async throws {
    do {
      var sdItem: SDBankAccount
      if let existing = try context.fetch(
        FetchDescriptor<SDBankAccount>(predicate: #Predicate { $0.id == account.id })
      ).first {
        sdItem = existing
        sdItem.name     = account.name
        sdItem.balance  = NSDecimalNumber(decimal: account.balance).doubleValue
        sdItem.currency = account.currency
        sdItem.updatedAt = account.updatedAt
      } else {
        sdItem = SDBankAccount(
          id:        account.id,
          userId:    account.userId,
          name:      account.name,
          balance:   NSDecimalNumber(decimal: account.balance).doubleValue,
          currency:  account.currency,
          createdAt: account.createdAt,
          updatedAt: account.updatedAt
        )
        context.insert(sdItem)
      }
      
      try context.save()
      
      try await backup.remove(id: account.id)
    } catch {
      let txBackup = account.toBalanceTransaction()
      try await backup.upsert(txBackup, action: .update)
    }
  }
}
