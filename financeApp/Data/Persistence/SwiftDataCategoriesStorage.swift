import Foundation
import SwiftData

@MainActor
final class SwiftDataCategoriesStorage: CategoriesStorageProtocol {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func fetchAll() async throws -> [Category] {
        let sdCats: [SDCategory] = try context.fetch(
            FetchDescriptor<SDCategory>(predicate: nil, sortBy: [
                SortDescriptor(\.id)
            ])
        )
        return sdCats.map { sd in
            let direction: Direction
            switch sd.directionRaw.lowercased() {
            case "income":  direction = .income
            case "outcome": direction = .outcome
            default:        direction = .outcome
            }
            
            return Category(
                id:        sd.id,
                name:      sd.name,
                emoji: sd.emoji.first ?? "❓",
                direction: direction
            )
        }
    }
    
    func saveAll(_ cats: [Category]) async throws {
        let existing: [SDCategory] = try context.fetch(
            FetchDescriptor<SDCategory>(predicate: nil)
        )
        for sd in existing {
            context.delete(sd)
        }
        
        for cat in cats {
            let emojiString = String(cat.emoji)
            let directionString: String
            switch cat.direction {
            case .income:  directionString = "income"
            case .outcome: directionString = "outcome"
            }
            
            let sd = SDCategory(
                id:           cat.id,
                name:         cat.name,
                emoji:        emojiString,
                directionRaw: directionString
            )
            context.insert(sd)
        }
        
        try context.save()
    }
}
