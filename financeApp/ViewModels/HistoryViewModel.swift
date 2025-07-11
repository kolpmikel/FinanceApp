import Foundation
import Combine

enum SortType: String, CaseIterable, Identifiable {
    case date   = "По дате"
    case amount = "По сумме"
    var id: String { rawValue }
}

@MainActor
final class HistoryViewModel: ObservableObject {
    let direction: Direction
    
    @Published var startDate: Date = {
        Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    }()
    @Published var endDate: Date = Date()
    @Published var sortType: SortType = .date
    
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var categories:    [Category]   = []
    
    private let transactionsService = MockTransactionsService.shared
    private let categoriesService   = MockCategoriesService()
    
    private var cancellables = Set<AnyCancellable>()
    
    init(direction: Direction) {
        self.direction = direction
        
        Task { await loadCategories() }
        
        Publishers
            .CombineLatest($startDate, $endDate)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _ in
                Task { await self?.loadTransactions() }
            }
            .store(in: &cancellables)
    }
    
    var filteredTransactions: [Transaction] {
        let filtered = transactions.filter { tx in
            guard let cat = categories.first(where: { $0.id == tx.categoryId }) else {
                return false
            }
            return cat.direction == direction
        }
        
        switch sortType {
        case .date:
            return filtered.sorted { $0.transactionDate > $1.transactionDate }
        case .amount:
            return filtered.sorted { $0.amount > $1.amount }
        }
    }
    
    var totalAmount: Decimal {
        filteredTransactions
            .map(\.amount)
            .reduce(0, +)
    }
    
    var totalAmountString: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.groupingSeparator = " "
        fmt.maximumFractionDigits = 2
        return (fmt.string(from: totalAmount as NSNumber) ?? "0") + " ₽"
    }
    
    private func loadCategories() async {
        do {
            categories = try await categoriesService.fetchAll()
        } catch {
            print("Ошибка загрузки категорий:", error)
        }
    }
    
    func loadTransactions() async {
        do {
            let dayStart = Calendar.current.startOfDay(for: startDate)
            let dayEnd   = Calendar.current.date(
                bySettingHour: 23,
                minute: 59,
                second: 59,
                of: Calendar.current.startOfDay(for: endDate)
            )!
            let interval = DateInterval(start: dayStart, end: dayEnd)
            transactions = try await transactionsService.getTransactionsOfPeriod(interval: interval)
        } catch {
            print("Ошибка загрузки транзакций:", error)
        }
    }
}
