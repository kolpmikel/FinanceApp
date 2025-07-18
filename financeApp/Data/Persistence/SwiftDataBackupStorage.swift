import Foundation
import SwiftData

@MainActor
final class SwiftDataBackupStorage: BackupStorageProtocol {
  private let context: ModelContext

  init(context: ModelContext) {
    self.context = context
  }

  func upsert(_ tx: Transaction, action: BackupAction) async throws {
    let data = try JSONEncoder().encode(tx)
    if let existing = try context.fetch(
      FetchDescriptor<BackupItem>(
        predicate: #Predicate { $0.id == tx.id }
      )
    ).first {
      existing.actionRaw = action.rawValue
      existing.txData    = data
    } else {
      context.insert(BackupItem(id: tx.id, action: action, txData: data))
    }
    try context.save()
  }

  func remove(id: Int) async throws {
    if let item = try context.fetch(
      FetchDescriptor<BackupItem>(
        predicate: #Predicate { $0.id == id }
      )
    ).first {
      context.delete(item)
      try context.save()
    }
  }

  func fetchAll() async throws -> [BackupItem] {
    try context.fetch(
      FetchDescriptor<BackupItem>(
        sortBy: [ SortDescriptor(\.id) ]
      )
    )
  }
}
