import SwiftUI

struct TransactionsListView: View {
    let direction: Direction
    @StateObject private var viewModel: TransactionsListViewModel

    @State private var editingTransaction: Transaction?
    @State private var isPresentingCreate = false

    init(direction: Direction) {
        self.direction = direction
        _viewModel = StateObject(
            wrappedValue: TransactionsListViewModel(direction: direction)
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                content
                if viewModel.isProcessing {
                    loadingOverlay
                }
            }
        }
        .tint(.blue)
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
            await viewModel.loadData()
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 5) {
            header
            transactionsList
        }
        .background(Color(.systemGray6))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
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
        }
    }

    private var transactionsList: some View {
        List {
            HStack {
                Text("Всего")
                Spacer()
                Text(viewModel.totalAmountString)
            }

            Section(header: Text("Операции")) {
                ForEach(viewModel.filteredTransactions) { tx in
                    let cat = viewModel.categories.first { $0.id == tx.categoryId }
                    transactionRow(tx: tx, category: cat)
                }
            }
        }
        .listSectionSpacing(10)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGray6))
        .sheet(
            item: $editingTransaction,
            onDismiss: { Task { await viewModel.loadData() } }
        ) { tx in
            MyTransactionView(direction: direction, transaction: tx)
        }
        .overlay(createButton, alignment: .bottomTrailing)
    }

    @ViewBuilder
    private func transactionRow(tx: Transaction, category: Category?) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.25))
                    .frame(width: 32, height: 32)
                Text(String(category?.emoji ?? "❓"))
                    .font(.system(size: 15))
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(category?.name ?? "Категория \(tx.categoryId)")
                    .fontWeight(.medium)
                if let comment = tx.comment {
                    Text(comment)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Text("\(tx.amount) ₽")
                .fontWeight(.medium)
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingTransaction = tx
        }
    }

    private var createButton: some View {
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
        .sheet(
            isPresented: $isPresentingCreate,
            onDismiss: { Task { await viewModel.loadData() } }
        ) {
            MyTransactionView(direction: direction)
        }
        .padding(.trailing, 16)
        .padding(.bottom, 16)
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.gray)
                .scaleEffect(1.5)
        }
    }
}

#Preview {
    TransactionsListView(direction: .outcome)
}
