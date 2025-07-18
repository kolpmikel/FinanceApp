import SwiftUI

struct HistoryView: View {
    let direction: Direction
    @StateObject private var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(direction: Direction) {
        self.direction = direction
        _viewModel = StateObject(wrappedValue: HistoryViewModel(direction: direction))
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Моя история")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                    
                    List {
                        rangeSection
                        sortSection
                        sumSection
                        transactionsSection
                    }
                    .listSectionSpacing(0)
                    .listRowBackground(Color.clear)
                }
                .background(Color(.systemGray6))
                .toolbar { trailingToolbar }
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .tint(Color.gray)
                    .scaleEffect(1.5)
            }
        }
        .alert(
            viewModel.errorMessage ?? "",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        }
        .task {
            await viewModel.loadCategories()
            await viewModel.loadTransactions()
        }
    }
    
    private var rangeSection: some View {
        Group {
            HStack {
                Text("Начало")
                Spacer()
                DatePicker("",
                           selection: $viewModel.startDate,
                           in: ...Date(),
                           displayedComponents: .date)
                .compactStyled()
                .onChange(of: viewModel.startDate) { old, new in
                    if new > viewModel.endDate {
                        viewModel.endDate = new
                    }
                    Task { await viewModel.loadTransactions() }
                }
            }
            HStack {
                Text("Конец")
                Spacer()
                DatePicker("",
                           selection: $viewModel.endDate,
                           in: ...Date(),
                           displayedComponents: .date)
                .compactStyled()
                .onChange(of: viewModel.endDate) { old, new in
                    if new < viewModel.startDate {
                        viewModel.startDate = new
                    }
                    Task { await viewModel.loadTransactions() }
                }
            }
        }
    }
    
    private var sortSection: some View {
        HStack {
            Text("Сортировка")
            Spacer()
            Picker("", selection: $viewModel.sortType) {
                ForEach(SortType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.3)))
            .cornerRadius(8)
        }
    }
    
    private var sumSection: some View {
        HStack {
            Text("Сумма")
            Spacer()
            Text(viewModel.totalAmountString)
        }
    }
    
    private var transactionsSection: some View {
        Section(header: Text("Операции")) {
            ForEach(viewModel.filteredTransactions) { transaction in
                transactionRow(transaction)
            }
        }
    }
    
    @ViewBuilder
    private func transactionRow(_ transaction: Transaction) -> some View {
        let category = viewModel.categories.first(where: { $0.id == transaction.categoryId })
        let emojiString = category.map { String($0.emoji) } ?? "❓"
        
        HStack {
            Circle()
                .fill(Color.green.opacity(0.25))
                .frame(width: 22, height: 22)
                .overlay(
                    Text(emojiString)
                        .font(.system(size: 12))
                )
                .padding(.trailing, 8)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(category?.name ?? "Категория \(transaction.categoryId ?? -1)")
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
    
    private var trailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink {
                AnalysisView(transactions: viewModel.transactions,
                             categories: viewModel.categories)
                .background(Color(.systemGroupedBackground))
            } label: {
                Image(systemName: "document")
            }
        }
    }
}

private extension DatePicker where Label == Text {
    func compactStyled() -> some View {
        self
            .tint(.black)
            .datePickerStyle(.compact)
            .labelsHidden()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.3))
            )
    }
}

#Preview {
    HistoryView(direction: .income)
}
