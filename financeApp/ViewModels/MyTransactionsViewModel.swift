import Foundation

@MainActor
class MyTransactionViewModel: ObservableObject {
    @Published var selectedCategory: Category?
    @Published var amountString: String
    @Published var date: Date
    @Published var comment: String
    
    @Published private(set) var categories: [Category] = []
    
    @Published var isProcessing: Bool = false
    
    let direction: Direction
    private let editingTransaction: Transaction?
    private let txService: MockTransactionsService
    private let accService: MockBankAccountsService
    private let catService: MockCategoriesService
    
    init(
        direction: Direction,
        transaction: Transaction? = nil,
        txService: MockTransactionsService = .shared,
        accService: MockBankAccountsService = .init(),
        catService: MockCategoriesService = .init()
    ) {
        self.direction = direction
        self.editingTransaction = transaction
        self.txService = txService
        self.accService = accService
        self.catService = catService
        
        self.date = transaction?.transactionDate ?? Date()
        self.amountString = transaction != nil
        ? NSDecimalNumber(decimal: transaction!.amount).stringValue
        : ""
        self.comment = transaction?.comment ?? ""
        
        Task { await loadCategories() }
    }
    
    func loadCategories() async {
        do {
            let cats = try await catService.fetch(by: direction)
            categories = cats
            if let tx = editingTransaction {
                selectedCategory = cats.first { $0.id == tx.categoryId }
            }
        } catch {
            print("Ошибка загрузки категорий:", error)
        }
    }
    
    func selectCategory(_ cat: Category) {
        selectedCategory = cat
    }
    
    var canSubmit: Bool {
        guard selectedCategory != nil else { return false }
        guard !amountString.isEmpty,
              Decimal(string: amountString) != nil
        else { return false }
        return true
    }
    
    func createTransaction() {
        guard canSubmit else { return }
        isProcessing = true
        Task {
            defer { isProcessing = false }
            do {
                let account = try await accService.fetchPrimary()
                let amount = Decimal(string: amountString)!
                let newTx = Transaction(
                    id: 0,
                    accountId: account.id,
                    categoryId: selectedCategory!.id,
                    amount: amount,
                    transactionDate: date,
                    comment: comment.isEmpty ? nil : comment,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                _ = try await txService.create(newTx)
            } catch {
                print("Ошибка создания:", error)
            }
        }
    }
    
    func updateTransaction() {
        guard canSubmit, var tx = editingTransaction else { return }
        isProcessing = true
        Task {
            defer { isProcessing = false }
            do {
                tx.categoryId = selectedCategory!.id
                tx.amount = Decimal(string: amountString)!
                tx.transactionDate = date
                tx.comment = comment.isEmpty ? nil : comment
                _ = try await txService.update(tx)
            } catch {
                print("Ошибка обновления:", error)
            }
        }
    }
    
    func deleteTransaction() {
        guard let tx = editingTransaction else { return }
        isProcessing = true
        Task {
            defer { isProcessing = false }
            do {
                try await txService.delete(id: tx.id)
            } catch {
                print("Ошибка удаления:", error)
            }
        }
    }
}
