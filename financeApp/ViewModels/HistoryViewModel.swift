import SwiftUI

enum SortType: String, CaseIterable, Identifiable {
    case date = "По дате"
    case amount = "По сумме"
    var id: String { self.rawValue }
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
    @Published private(set) var categories: [Category] = []
    
    private var transactionsService = MockTransactionsService()
    private var categoriesService = MockCategoriesService()
    
    init(direction: Direction) {
        self.direction = direction
        fetchData()
    }
    
    
    var filteredTransactions: [Transaction] {
        let filtered = transactions.filter { transaction in
            if let category = categories.first(where: { $0.id == transaction.categoryId }) {
                return category.direction == direction
            }
            return false
        }
        switch sortType {
        case .date:
            return filtered.sorted { $0.transactionDate > $1.transactionDate }
        case .amount:
            return filtered.sorted { $0.amount > $1.amount }
        }
    }
    
    var totalAmount: Decimal {
        var sum: Decimal = 0
        for transaction in filteredTransactions {
            sum += transaction.amount
        }
        return sum
    }
    
    var totalAmountString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.maximumFractionDigits = 2
        return (formatter.string(for: totalAmount) ?? "0") + " ₽"
    }
    func fetchData() {
        Task {
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
                
            }
            
            do {
                categories = try await categoriesService.fetchAll()
            } catch {
                
            }
        }
    }
}
