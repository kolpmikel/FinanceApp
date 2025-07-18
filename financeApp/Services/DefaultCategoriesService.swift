import Foundation

@MainActor
final class DefaultCategoriesService: CategoriesServiceProtocol {
    private let api: APICategoriesService
    private let storage: CategoriesStorageProtocol

    init(
        api: APICategoriesService = .shared,
        storage: CategoriesStorageProtocol
    ) {
        self.api = api
        self.storage = storage
    }

    func fetchAll() async throws -> [Category] {
        do {
            let remote = try await api.fetchAll()
            try await storage.saveAll(remote)
            return remote
        } catch {
            return try await storage.fetchAll()
        }
    }

    func fetch(by direction: Direction) async throws -> [Category] {
        let all = try await fetchAll()
        return all.filter { $0.direction == direction }
    }
}
