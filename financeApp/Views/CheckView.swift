import SwiftUI

struct CheckView: View {
    @StateObject private var viewModel = CheckViewModel()

    @State private var isEditing = false
    @State private var name: String    = ""
    @State private var balance: Double = 0
    @State private var editingCurrency: String = "RUB"

    @FocusState private var balanceFieldIsFocused: Bool
    @State private var isCurrencyDialogPresented = false
    @State private var isBalanceHidden = false

    private var formattedBalance: String {
        let style = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0...2))
        return style.format(balance) + " " + currencySymbol(for: editingCurrency)
    }

    var body: some View {
        NavigationStack {
            mainList
                .navigationTitle("Мой счет")
                .toolbar { toolBarSection }
                .gesture(
                    DragGesture().onEnded { value in
                        if value.translation.height > 0 { balanceFieldIsFocused = false }
                    }
                )
                .task {
                    await viewModel.loadData()
                    if let acct = viewModel.bankAccount {
                        name            = acct.name
                        balance         = NSDecimalNumber(decimal: acct.balance).doubleValue
                        editingCurrency = acct.currency
                    }
                }
                .refreshable { await viewModel.loadData() }
                .onChange(of: viewModel.bankAccount) { _, new in
                    if let acct = new {
                        name            = acct.name
                        balance         = NSDecimalNumber(decimal: acct.balance).doubleValue
                        editingCurrency = acct.currency
                    }
                }
                .alert(viewModel.errorMessage ?? "", isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )) {
                    Button("OK", role: .cancel) { viewModel.errorMessage = nil }
                }
                .overlay {
                    if viewModel.isLoading {
                        ZStack {
                            Color.black.opacity(0.3).ignoresSafeArea()
                            ProgressView().scaleEffect(1.5)
                        }
                    }
                }
        }
    }

    // MARK: - Main List
    private var mainList: some View {
        List {
            balanceSection
                .listRowBackground(isEditing ? Color.white : Color.accentColor)

            curencySection
                .listRowBackground(isEditing ? Color.white : Color.accentColor.opacity(0.3))

            if !isEditing {
                chartSection
                    .listRowBackground(Color(.systemBackground))
            }
        }
        .listSectionSpacing(20)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGray6))
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
    }

    // MARK: - Sections
    private var chartSection: some View {
        Section {
            if viewModel.dailyBalances.isEmpty {
                Text("Нет данных для графика")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                BalanceChartView(points: viewModel.dailyBalances)
                    .transition(.opacity)
                
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color(.systemGray6))
        
    }

    private var balanceSection: some View {
        Section {
            HStack {
                Text("💰  Баланс")
                Spacer()
                if isEditing {
                    TextField("", value: $balance, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($balanceFieldIsFocused)
                        .submitLabel(.done)
                        .onSubmit { balanceFieldIsFocused = false }
                } else {
                    if isBalanceHidden {
                        Text(formattedBalance).spoiler(isOn: $isBalanceHidden)
                    } else {
                        Text(formattedBalance).transition(.opacity)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { if isEditing { balanceFieldIsFocused = true } }

            if isEditing {
                HStack {
                    Spacer()
                    Button("Вставить") { pasteFromClipboard() }
                        .foregroundColor(.blue)
                        .padding(6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
    }

    private var curencySection: some View {
        Section {
            HStack {
                Text("Валюта")
                Spacer()
                if isEditing {
                    Button {
                        isCurrencyDialogPresented = true
                    } label: {
                        HStack {
                            Text(currencySymbol(for: editingCurrency)).foregroundColor(.gray)
                            Image(systemName: "chevron.right").foregroundColor(.gray)
                        }
                    }
                    .confirmationDialog("Валюта", isPresented: $isCurrencyDialogPresented) {
                        Button("Российский рубль ₽") { editingCurrency = "RUB" }
                        Button("Американский доллар $") { editingCurrency = "USD" }
                        Button("Евро €") { editingCurrency = "EUR" }
                    }
                } else {
                    Text(currencySymbol(for: editingCurrency))
                }
            }
        }
    }

    // MARK: - Toolbar
    private var toolBarSection: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if isEditing {
                Button("Сохранить") {
                    isEditing = false
                    Task {
                        await viewModel.updateAccount(
                            name: name,
                            balance: Decimal(balance),
                            currency: editingCurrency
                        )
                    }
                }
            } else {
                Button("Редактировать") { isEditing = true }
            }
        }
    }

    // MARK: - Helpers
    private func pasteFromClipboard() {
        if let clipboard = UIPasteboard.general.string {
            let cleaned = clipboard
                .filter { "0123456789.,".contains($0) }
                .replacingOccurrences(of: ",", with: ".")
            var parts = cleaned.split(separator: ".")
            let joined: String
            if parts.count > 2 {
                let whole = parts.removeFirst()
                joined = "\(whole)." + parts.joined()
            } else {
                joined = cleaned
            }
            if let value = Double(joined) {
                balanceFieldIsFocused = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    balance = value
                }
            }
        }
    }

    private func currencySymbol(for code: String) -> String {
        switch code {
        case "RUB": return "₽"
        case "USD": return "$"
        case "EUR": return "€"
        default:    return code
        }
    }
}

#Preview {
    CheckView()
}
