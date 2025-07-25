import Foundation

extension Encodable {
    /// Возвращает красивый JSON того же формата, что уйдёт через JSONEncoderWithDates
    func prettyJSON(encoder: JSONEncoder = JSONEncoderWithDates) -> String {
        let enc = encoder
        if #available(iOS 13.0, *) {
            enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        } else {
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        do {
            let data = try enc.encode(self)
            return String(data: data, encoding: .utf8) ?? "<non-utf8>"
        } catch {
            return "❌ encode error: \(error)"
        }
    }
}

@MainActor
class MyTransactionViewModel: ObservableObject {
    @Published var selectedCategory: Category?
    @Published var amountString: String
    @Published var date: Date
    @Published var comment: String
    
    @Published private(set) var categories: [Category] = []
    
    @Published var isLoading: Bool       = false
    @Published var isProcessing: Bool    = false
    @Published var errorMessage: String? = nil
    
    let direction: Direction
    private var editingTransaction: Transaction?
    private let txService: any TransactionsServiceProtocol
    private let accService: any BankAccountsServiceProtocol
    private let catService: any CategoriesServiceProtocol
    
    init(
        direction: Direction,
        transaction: Transaction? = nil,
        txService:     any TransactionsServiceProtocol   = APITransactionsService.shared,
        accService:    any BankAccountsServiceProtocol  = APIBankAccountsService.shared,
        catService:    any CategoriesServiceProtocol    = APICategoriesService.shared
    ) {
        self.direction         = direction
        self.editingTransaction = transaction
        self.txService         = txService
        self.accService        = accService
        self.catService        = catService
        
        self.date         = transaction?.transactionDate ?? Date()
        self.amountString = transaction != nil
        ? NSDecimalNumber(decimal: transaction!.amount).stringValue
        : ""
        self.comment      = transaction?.comment ?? ""
        
        Task { await loadCategories() }
    }
    
    func loadCategories() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let cats = try await catService.fetch(by: direction)
            categories = cats
            if let tx = editingTransaction {
                selectedCategory = cats.first { $0.id == tx.categoryId }
            }
        } catch {
            errorMessage = makeUserMessage(from: error)
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
        errorMessage  = nil
        
        Task {
            defer { isProcessing = false }
            do {
                let account = try await accService.fetchPrimary()
                let amount  = Decimal(string: amountString)!
                let newTx = Transaction(
                    id:             0,
                    accountId:      account.id,
                    categoryId:     selectedCategory!.id,
                    amount:         amount,
                    transactionDate: date,
                    comment:        comment.isEmpty ? nil : comment,
                    createdAt:      Date(),
                    updatedAt:      Date()
                )
                let createdPayload = newTx.prettyJSON()
                print("➡️ CREATE TX BODY:\n\(createdPayload)")
//                let created = try await txService.create(newTx)
                
                let created = try await txService.create(newTx)
                print("⬅️ CREATED:", created.id, created.transactionDate)

                NotificationCenter.default.post(name: .transactionsDidChange, object: nil)
            } catch {
                errorMessage = makeUserMessage(from: error)
            }
        }
    }
    
    func updateTransaction() {
        guard canSubmit, var tx = editingTransaction else { return }
        isProcessing  = true
        errorMessage   = nil
        
        Task {
            defer { isProcessing = false }
            do {
                if tx.accountId == nil {
                    let acct = try await accService.fetchPrimary()
                    tx.accountId = acct.id
                }
                tx.categoryId      = selectedCategory!.id
                tx.amount          = Decimal(string: amountString)!
                tx.transactionDate = date
                tx.comment         = comment.isEmpty ? nil : comment
                
                _ = try await txService.update(tx)
                NotificationCenter.default.post(name: .transactionsDidChange, object: nil)
            } catch {
                errorMessage = makeUserMessage(from: error)
            }
        }
    }
    
    func deleteTransaction() {
        guard let tx = editingTransaction else { return }
        isProcessing = true
        errorMessage  = nil
        
        Task {
            defer { isProcessing = false }
            do {
                try await txService.delete(id: tx.id)
                NotificationCenter.default.post(name: .transactionsDidChange, object: nil)
            } catch {
                errorMessage = makeUserMessage(from: error)
            }
        }
    }
}
