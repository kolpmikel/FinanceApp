import SwiftUI

struct MyTransactionView: View {
    let direction: Direction
    let editingTransaction: Transaction?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MyTransactionViewModel
    @State private var showValidationAlert = false
    
    init(direction: Direction, transaction: Transaction? = nil) {
        self.direction = direction
        self.editingTransaction = transaction
        _viewModel = StateObject(
            wrappedValue: MyTransactionViewModel(
                direction: direction,
                transaction: transaction
            )
        )
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                Form {
                    Section {
                        HStack {
                            Text("Статья")
                            Spacer()
                            Menu {
                                ForEach(viewModel.categories) { cat in
                                    Button(cat.name) {
                                        viewModel.selectCategory(cat)
                                    }
                                }
                            } label: {
                                Text(viewModel.selectedCategory?.name ?? "Выберите")
                                    .foregroundColor(
                                        viewModel.selectedCategory == nil
                                        ? .gray : .primary
                                    )
                            }
                        }
                        HStack {
                            Text("Сумма")
                            Spacer()
                            AmountField(amountString: $viewModel.amountString)
                        }
                        HStack {
                            Text("Дата")
                            Spacer()
                            DatePicker(
                                "",
                                selection: $viewModel.date,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .compactStyled()
                        }
                        HStack {
                            Text("Время")
                            Spacer()
                            DatePicker(
                                "",
                                selection: $viewModel.date,
                                in: ...Date(),
                                displayedComponents: .hourAndMinute
                            )
                            .compactStyled()
                        }
                        HStack {
                            Text("Комментарий")
                            Spacer()
                            TextField(
                                "Комментарий",
                                text: $viewModel.comment
                            )
                            .foregroundColor(
                                viewModel.comment.isEmpty
                                ? .gray : .primary
                            )
                            .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    if editingTransaction != nil {
                        Section {
                            Button("Удалить операцию", role: .destructive) {
                                viewModel.deleteTransaction()
                                dismiss()
                            }
                        }
                    }
                }
                .navigationTitle(navigationTitle)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(editingTransaction == nil ? "Создать" : "Сохранить") {
                            if viewModel.canSubmit {
                                if editingTransaction == nil {
                                    viewModel.createTransaction()
                                } else {
                                    viewModel.updateTransaction()
                                }
                                dismiss()
                            } else {
                                showValidationAlert = true
                            }
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") { dismiss() }
                    }
                }
                .alert(
                    "Пожалуйста, заполните все обязательные поля",
                    isPresented: $showValidationAlert
                ) {
                    Button("OK", role: .cancel) { }
                }
            }
            
            if viewModel.isLoading || viewModel.isProcessing {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
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
    }
    
    private var navigationTitle: String {
        if editingTransaction == nil {
            return direction == .income
            ? "Новый доход" : "Новый расход"
        } else {
            return "Редактировать"
        }
    }
}

private extension DatePicker where Label == Text {
    func compactStyled() -> some View {
        self
            .tint(.black)
            .datePickerStyle(CompactDatePickerStyle())
            .labelsHidden()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.3))
            )
    }
}

struct AmountField: View {
    @Binding var amountString: String
    
    private var decimalSeparator: String {
        Locale.current.decimalSeparator ?? "."
    }
    
    var body: some View {
        TextField("Сумма", text: $amountString)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .onChange(of: amountString) { _, newValue in
                let sep = decimalSeparator
                let allowed = CharacterSet.decimalDigits
                    .union(.init(charactersIn: sep))
                var filtered = newValue
                    .unicodeScalars
                    .filter { allowed.contains($0) }
                    .map(String.init)
                    .joined()
                let parts = filtered.components(separatedBy: sep)
                if parts.count > 2 {
                    filtered = parts[0] + sep + parts[1]
                }
                if filtered != newValue {
                    amountString = filtered
                }
            }
    }
}
