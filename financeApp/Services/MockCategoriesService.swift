import Foundation

protocol CategoriesServiceProtocol {
    func fetchAll() async throws -> [Category]
    func fetch(by direction: Direction) async throws -> [Category]
}

final class MockCategoriesService: CategoriesServiceProtocol {
    
    private let sample: [Category] = [
        Category(id: 1, name: "Зарплата", emoji: "💰", direction: .income),
        Category(id: 2, name: "Подарки", emoji: "🎁", direction: .income),
        Category(id: 3, name: "Продукты", emoji: "🛒", direction: .outcome),
        Category(id: 4, name: "Кофе", emoji: "☕️", direction: .outcome),
        Category(id: 5, name: "Развлечения", emoji: "🎉", direction: .outcome)
    ]
    
    func fetchAll() async throws -> [Category] {
        return sample
    }
    
    func fetch(by direction: Direction) async throws -> [Category] {
        let all = try await fetchAll()
        return all.filter { $0.direction == direction }
    }
}
