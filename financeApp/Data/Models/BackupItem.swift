import Foundation
import SwiftData

@Model
final class BackupItem {
  @Attribute(.unique) var id: Int
  var actionRaw: String
  var txData: Data

  init(id: Int, action: BackupAction, txData: Data) {
    self.id = id
    self.actionRaw = action.rawValue
    self.txData = txData
  }

  var action: BackupAction { BackupAction(rawValue: actionRaw)! }
  func transaction() throws -> Transaction {
    try JSONDecoder().decode(Transaction.self, from: txData)
  }
}
