import SwiftUI

@MainActor
class ArticlesViewModel: ObservableObject {
    @Published var categories: [Category] = []

    private let service: CategoriesServiceProtocol

    init(service: CategoriesServiceProtocol = MockCategoriesService()) {
        self.service = service
    }

    func loadAll() async {
        do {
            categories = try await service.fetchAll()
        } catch {
            print("Failed to load categories:", error)
        }
    }
    
    func fuzzyMatch(_ pattern: String, _ text: String, maxDistance: Int = 2) -> Bool {
        let pattern = pattern.lowercased()
        let text = text.lowercased()
        
        let m = pattern.count
        let n = text.count
        
        guard m > 0, n > 0 else {
            return false
        }
        
        let patternChars = Array(pattern)
        let textChars = Array(text)
        
        for offset in 0...(n - m >= 0 ? n - m : 0) {
            let end = min(offset + m, n)
            let window = Array(textChars[offset..<end])
            let distance = levenshtein(patternChars, window)
            if distance <= maxDistance {
                return true
            }
        }

        return false
    }

    private func levenshtein(_ a: [Character], _ b: [Character]) -> Int {
        let m = a.count
        let n = b.count
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { dp[i][0] = i }
        for j in 0...n { dp[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                if a[i - 1] == b[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1]
                } else {
                    dp[i][j] = 1 + min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1])
                }
            }
        }

        return dp[m][n]
    }
}
