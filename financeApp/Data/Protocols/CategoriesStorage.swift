import Foundation

@MainActor
protocol CategoriesStorageProtocol {
  func fetchAll() async throws -> [Category]
  func saveAll(_ cats: [Category]) async throws
}
