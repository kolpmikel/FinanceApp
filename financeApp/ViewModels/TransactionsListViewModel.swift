import Foundation
import SwiftUI

@MainActor
class TransactionsListViewModel: ObservableObject {
    let direction: Direction
    
    private let transactionsService: MockTransactionsService
    private let categoriesService: MockCategoriesService
    
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    
    init(direction: Direction,
         transactionsService: MockTransactionsService = MockTransactionsService(),
         categoriesService: MockCategoriesService = MockCategoriesService()) {
        self.direction = direction
        self.transactionsService = transactionsService
        self.categoriesService = categoriesService
    }
    
    var filteredTransactions: [Transaction] {
        transactions.filter { tx in
            guard let catId = tx.categoryId,
                  let category = categories.first(where: { $0.id == catId })
            else { return false }
            return category.direction == direction
        }
    }
    
    var title: String {
        direction == .income ? "Доходы сегодня" : "Расходы сегодня"
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
    func loadData() async {
        do {
            let today = transactionsService.todayInterval()
            transactions = try await transactionsService.getTransactionsOfPeriod(interval: today)
        } catch {
            
        }
        
        do {
            categories = try await categoriesService.fetchAll()
        } catch {
            
        }
    }
}
