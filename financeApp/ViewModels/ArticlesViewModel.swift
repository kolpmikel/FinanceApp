import Foundation

@MainActor
class ArticlesViewModel: ObservableObject {
    @Published private(set) var categories: [Category] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let service: CategoriesServiceProtocol
    
    init(service: CategoriesServiceProtocol = APICategoriesService.shared) {
        self.service = service
    }
    
    func loadAll() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            categories = try await service.fetchAll()
        } catch {
            errorMessage = makeUserMessage(from: error)
        }
    }
    
    func load(type direction: Direction) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            categories = try await service.fetch(by: direction)
        } catch {
            errorMessage = makeUserMessage(from: error)
        }
    }
    
    var filteredCategories: [Category] {
        guard !searchText.isEmpty else {
            return categories
        }
        return categories.filter { fuzzyMatch(searchText, $0.name) }
    }
        
    private func fuzzyMatch(_ pattern: String, _ text: String, maxDistance: Int = 2) -> Bool {
        let p = pattern.lowercased(), t = text.lowercased()
        guard !p.isEmpty && !t.isEmpty else { return false }
        let pc = Array(p), tc = Array(t)
        let m = pc.count, n = tc.count
        var d = Array(repeating: Array(repeating: 0, count: n+1), count: m+1)
        for i in 0...m { d[i][0] = i }
        for j in 0...n { d[0][j] = j }
        for i in 1...m {
            for j in 1...n {
                if pc[i-1] == tc[j-1] {
                    d[i][j] = d[i-1][j-1]
                } else {
                    d[i][j] = 1 + min(d[i-1][j], d[i][j-1], d[i-1][j-1])
                }
            }
        }
        return (0...n - m).contains { start in
            let dist = d[m][start+m]
            return dist <= maxDistance
        }
    }
    
    private func levenshteinDistance(
        between sourceCharacters: [Character],
        and   targetCharacters: [Character]
    ) -> Int {
        let sourceLength = sourceCharacters.count
        let targetLength = targetCharacters.count
        
        var distanceMatrix = Array(
            repeating: Array(repeating: 0, count: targetLength + 1),
            count: sourceLength + 1
        )
        
        for sourceIndex in 0...sourceLength {
            distanceMatrix[sourceIndex][0] = sourceIndex
        }
        for targetIndex in 0...targetLength {
            distanceMatrix[0][targetIndex] = targetIndex
        }
        
        for sourceIndex in 1...sourceLength {
            for targetIndex in 1...targetLength {
                if sourceCharacters[sourceIndex - 1] == targetCharacters[targetIndex - 1] {
                    distanceMatrix[sourceIndex][targetIndex] = distanceMatrix[sourceIndex - 1][targetIndex - 1]
                } else {
                    let deletionDistance     = distanceMatrix[sourceIndex - 1][targetIndex]
                    let insertionDistance    = distanceMatrix[sourceIndex][targetIndex - 1]
                    let substitutionDistance = distanceMatrix[sourceIndex - 1][targetIndex - 1]
                    
                    distanceMatrix[sourceIndex][targetIndex] =
                    1 + min(deletionDistance, insertionDistance, substitutionDistance)
                }
            }
        }
        
        return distanceMatrix[sourceLength][targetLength]
    }
}
