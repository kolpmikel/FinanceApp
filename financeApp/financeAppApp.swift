import SwiftUI
import SwiftData

@main
struct financeAppApp: App {
    @State private var showSplash = true
    
    @StateObject private var storageHolder: StorageHolder
    
    let container = try! ModelContainer(for: SDBankAccount.self, BackupItem.self)
    
    
    init() {
        let txStorage   = try! SwiftDataTransactionsStorage()
        let backup      = SwiftDataBackupStorage(context: txStorage.modelContext)
        let catStorage  = SwiftDataCategoriesStorage(context: txStorage.modelContext)
        let acctStorage = SwiftDataBankAccountsStorage(
            context: txStorage.modelContext,
            backup: backup
        )
        
        let txService   = DefaultTransactionsService(
            api:           .shared,
            storage:       txStorage,
            backupStorage: backup
        )
        let catService  = DefaultCategoriesService(
            api:     .shared,
            storage: catStorage
        )
        let acctService = DefaultBankAccountsService(
            api:           .shared,
            storage:       acctStorage,
            backupStorage: backup
        )
        
        _storageHolder = StateObject(
            wrappedValue: StorageHolder(
                txService:    txService,
                acctService:  acctService,
                catService:   catService,
                modelContext: txStorage.modelContext
            )
        )
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                TabBarView()
                    .environment(\.modelContext, storageHolder.modelContext)
                .environmentObject(storageHolder)
                .opacity(showSplash ? 0 : 1)

                
                // Сплэш-сцена поверх
                               if showSplash {
                                   SplashView {
                                       // Этот блок выполнится после окончания Lottie
                                       withAnimation(.easeOut(duration: 0.3)) {
                                           showSplash = false
                                       }
                                   }
                                   .transition(.opacity)
                               }
            }
            
            
        }
    }
}


@MainActor
final class StorageHolder: ObservableObject {
    let txService:   DefaultTransactionsService
    let acctService: DefaultBankAccountsService
    let catService:  DefaultCategoriesService
    let modelContext: ModelContext
    
    init(
        txService:    DefaultTransactionsService,
        acctService:  DefaultBankAccountsService,
        catService:   DefaultCategoriesService,
        modelContext: ModelContext
    ) {
        self.txService     = txService
        self.acctService   = acctService
        self.catService    = catService
        self.modelContext  = modelContext
    }
}

