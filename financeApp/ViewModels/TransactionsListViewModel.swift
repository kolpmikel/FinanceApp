import Foundation
import Combine

@MainActor
class TransactionsListViewModel: ObservableObject {
    let direction: Direction

    private let transactionsService: any TransactionsServiceProtocol
    private let categoriesService:   any CategoriesServiceProtocol

    private var cancellables = Set<AnyCancellable>()

    @Published var transactions: [Transaction] = []
    @Published var categories:   [Category]    = []
    @Published var isProcessing: Bool          = false
    @Published var errorMessage: String?       = nil

    init(
        direction: Direction,
        transactionsService: any TransactionsServiceProtocol = APITransactionsService.shared,
        categoriesService:   any CategoriesServiceProtocol   = APICategoriesService.shared
    ) {
        self.direction = direction
        self.transactionsService = transactionsService
        self.categoriesService   = categoriesService

        NotificationCenter.default
            .publisher(for: .transactionsDidChange)
            .sink { [weak self] _ in
                Task { await self?.loadData() }
            }
            .store(in: &cancellables)

        Task { await loadData() }
    }

    var filteredTransactions: [Transaction] {
        let filtered = transactions.filter { tx in
            guard let cat = categories.first(where: { $0.id == tx.categoryId }) else {
                return false
            }
            return cat.direction == direction
        }
        return filtered.sorted { $0.transactionDate > $1.transactionDate }
    }

    var title: String {
        direction == .income ? "Доходы сегодня" : "Расходы сегодня"
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

    func loadData() async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            categories = try await categoriesService.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }

        do {
            let today = transactionsService.todayInterval()
            transactions = try await transactionsService.getTransactions(of: today)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
