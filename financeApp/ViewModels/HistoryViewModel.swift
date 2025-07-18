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
    
    @Published var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @Published var endDate:   Date = Date()
    @Published var sortType:  SortType = .date
    
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var categories:    [Category]   = []
    
    @Published var isLoading:    Bool    = false
    @Published var errorMessage: String? = nil
    
    private let transactionsService: any TransactionsServiceProtocol
    private let categoriesService:   any CategoriesServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        direction: Direction,
        transactionsService: any TransactionsServiceProtocol = APITransactionsService.shared,
        categoriesService:   any CategoriesServiceProtocol   = APICategoriesService.shared
    ) {
        self.direction = direction
        self.transactionsService = transactionsService
        self.categoriesService   = categoriesService
        
        Task { await loadCategories() }
        Task { await loadTransactions() }
        
        Publishers
            .CombineLatest3($startDate, $endDate, $sortType)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
                Task { await self?.loadTransactions() }
            }
            .store(in: &cancellables)
    }
    
    var filteredTransactions: [Transaction] {
        let byDirection = transactions.filter { tx in
            guard let cat = categories.first(where: { $0.id == tx.categoryId }) else {
                return false
            }
            return cat.direction == direction
        }
        let dayStart = Calendar.current.startOfDay(for: startDate)
        let dayEnd   = Calendar.current.date(
            bySettingHour: 23, minute: 59, second: 59,
            of: Calendar.current.startOfDay(for: endDate)
        )!
        let byDate = byDirection.filter { tx in
            tx.transactionDate >= dayStart && tx.transactionDate <= dayEnd
        }
        switch sortType {
        case .date:
            return byDate.sorted { $0.transactionDate > $1.transactionDate }
        case .amount:
            return byDate.sorted { $0.amount > $1.amount }
        }
    }
    
    var totalAmount: Decimal {
        filteredTransactions.map(\.amount).reduce(0, +)
    }
    
    var totalAmountString: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.groupingSeparator = " "
        fmt.maximumFractionDigits = 2
        return (fmt.string(from: totalAmount as NSNumber) ?? "0") + " ₽"
    }
    
    func loadCategories() async {
        isLoading = true
        defer { isLoading = false }
        do {
            categories = try await categoriesService.fetchAll()
        } catch {
            errorMessage = makeUserMessage(from: error)
        }
    }
    
    func loadTransactions() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let dayStart = Calendar.current.startOfDay(for: startDate)
            let dayEnd = Calendar.current.date(
                bySettingHour: 23, minute: 59, second: 59,
                of: Calendar.current.startOfDay(for: endDate)
            )!
            let interval = DateInterval(start: dayStart, end: dayEnd)
            transactions = try await transactionsService.getTransactions(of: interval)
        } catch {
            errorMessage = makeUserMessage(from: error)
        }
    }
}
