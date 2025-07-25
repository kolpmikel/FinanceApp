import Foundation


struct DailyBalance: Identifiable {
    let id = UUID()
    let date: Date
    let income: Decimal    // сумма доходов за день
    let expense: Decimal   // сумма расходов за день (положительное число)
    var net: Decimal { income - expense } // итог дня
}

@MainActor
class CheckViewModel: ObservableObject {
    private let service: any BankAccountsServiceProtocol
     private let txService: any TransactionsServiceProtocol
     private let catService: any CategoriesServiceProtocol

     @Published var bankAccount: BankAccount?
     @Published var dailyBalances: [DailyBalance] = []
     @Published var isLoading = false
     @Published var errorMessage: String?

     init(service: any BankAccountsServiceProtocol = APIBankAccountsService.shared,
          txService: any TransactionsServiceProtocol = APITransactionsService.shared,
          catService: any CategoriesServiceProtocol = APICategoriesService.shared) {
         self.service   = service
         self.txService = txService
         self.catService = catService
     }

     func loadData() async {
         isLoading = true
         defer { isLoading = false }
         do {
             let acct = try await service.fetchPrimary()
             self.bankAccount = acct

             let interval = lastInterval(days: 30)
             async let txsTask: [Transaction] = txService.getTransactions(of: interval)
             async let catsTask: [Category]    = catService.fetchAll()

             let (txs, cats) = try await (txsTask, catsTask)
             rebuildDailyBalances(transactions: txs, categories: cats, days: 30)
         } catch {
             errorMessage = makeUserMessage(from: error)
         }
     }

     private func lastInterval(days: Int) -> DateInterval {
         let cal = Calendar.current
         let endDay = cal.startOfDay(for: Date()).addingTimeInterval(24*60*60 - 1)
         let startDay = cal.date(byAdding: .day, value: -(days - 1), to: cal.startOfDay(for: Date()))!
         return DateInterval(start: startDay, end: endDay)
     }

     /// Расчёт доходов/расходов по дню, используя направление категории
     private func rebuildDailyBalances(transactions: [Transaction],
                                       categories: [Category],
                                       days: Int = 30) {
         let cal   = Calendar.current
         let end   = cal.startOfDay(for: Date())
         let start = cal.date(byAdding: .day, value: -(days - 1), to: end)!

         // Словарь: id категории -> направление
         let dirByCat: [Int: Direction] = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.direction) })

         // Группировка транзакций по дню
         let grouped = Dictionary(grouping: transactions) { tx in
             cal.startOfDay(for: tx.transactionDate)
         }

         var result: [DailyBalance] = []
         var day = start
         while day <= end {
             var inc: Decimal = 0
             var exp: Decimal = 0
             for tx in grouped[day] ?? [] {
                 let dir = dirByCat[tx.categoryId ?? -1]
                 if dir == .income {
                     inc += tx.amount
                 } else {
                     exp += tx.amount   // здесь amount положительный
                 }
             }
             result.append(DailyBalance(date: day, income: inc, expense: exp))
             day = cal.date(byAdding: .day, value: 1, to: day)!
         }

         dailyBalances = result
     }

    func updateAccount(name: String, balance: Decimal, currency: String) async {
        guard var acct = bankAccount else { return }
        isLoading = true
        defer { isLoading = false }

        acct.name     = name
        acct.balance  = balance
        acct.currency = currency

        do {
            let updated = try await service.update(acct)
            bankAccount = updated
        } catch {
            errorMessage = makeUserMessage(from: error)
        }
    }
}
