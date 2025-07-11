import SwiftUI


struct TransactionsListView: View {
    let direction: Direction
    @StateObject private var viewModel: TransactionsListViewModel
    
    @State private var editingTransaction: Transaction?
    @State private var isPresentingCreate = false
    
    init(direction: Direction) {
        self.direction = direction
        _viewModel = StateObject(wrappedValue: TransactionsListViewModel(direction: direction))
    }
    
    var body: some View {
        NavigationStack {
            
            VStack (alignment: .leading, spacing: 5 ){
                NavigationLink(destination: HistoryView(direction: direction)) {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                        .font(.system(size: 22))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 20)
                }
                
                Text(viewModel.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal, 20)
                
                List {
                    HStack{
                        Text("Всего")
                        Spacer()
                        Text(viewModel.totalAmountString)
                        
                    }
                    
                    Section(header: Text("Операции")) {
                        ForEach(viewModel.filteredTransactions) { transaction in
                            
                            let category = viewModel.categories.first(where: { $0.id == transaction.categoryId })
                            
                            
                            HStack {
                                
                                ZStack{
                                    Circle()
                                        .fill(Color.green.opacity(0.25))
                                        .frame(width: 32, height: 32)
                                    Text(String(category?.emoji ?? "❓"))
                                        .font(.system(size: 15))
                                }
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(category?.name ?? "Категория \(String(describing: transaction.categoryId))")
                                        .fontWeight(.medium)
                                    if let comment = transaction.comment {
                                        Text(comment)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                Text("\(transaction.amount) ₽")
                                    .fontWeight(.medium)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingTransaction = transaction
                            }
                        }
                    }
                }
                .sheet(item: $editingTransaction) { tx in
                    MyTransactionView(
                        direction: direction,
                        transaction: tx
                    )
                    .onDisappear {
                        Task { await viewModel.loadData() }
                    }
                }
                .listSectionSpacing(10)
                
                HStack {
                    Spacer()
                    Button {
                        isPresentingCreate = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.green)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .sheet(isPresented: $isPresentingCreate) {
                        MyTransactionView(direction: direction)
                            .onDisappear { Task { await viewModel.loadData() } }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGray6))
            .task {
                await viewModel.loadData()
            }
            
        }
        .tint(Color.blue)
        
        
    }
}

#Preview {
    TransactionsListView(direction: .outcome)
}
