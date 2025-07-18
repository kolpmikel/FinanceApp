import Foundation


final class APICategoriesService: CategoriesServiceProtocol {
    static let shared = APICategoriesService()
    init() {}
    
    func fetchAll() async throws -> [Category] {
        return try await NetworkClient.shared.request(
            path:   "categories",
            method: .GET,
            body:   EmptyBody()
        )
    }
    
    func fetch(by direction: Direction) async throws -> [Category] {
        
        let flag = direction == .income ? "true" : "false"
        return try await NetworkClient.shared.request(
            path:   "categories/type/\(flag)",
            method: .GET,
            body:   EmptyBody()
        )
    }
}
