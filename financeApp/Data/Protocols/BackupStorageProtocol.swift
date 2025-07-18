import Foundation

@MainActor
protocol BackupStorageProtocol {
  func upsert(_ tx: Transaction, action: BackupAction) async throws
  func remove(id: Int) async throws
  func fetchAll() async throws -> [BackupItem]
}
