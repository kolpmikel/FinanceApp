import SwiftUI

struct TransactionsListView: View {
    let direction: Direction
    @StateObject private var viewModel: TransactionsListViewModel
    
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
                                Circle()
                                    .fill(Color.green.opacity(0.25))
                                    .frame(width: 22, height: 22)
                                    .overlay(Text(String(category?.emoji ?? "❓"))
                                        .font(.caption)
                                    )
                                
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
                        }
                    }
                }
                .listSectionSpacing(10)
                
                HStack {
                    Spacer()
                    NavigationLink(destination: MyTransactions()){
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.green)
                            .clipShape(Circle())
                            .shadow(radius: 4)
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
