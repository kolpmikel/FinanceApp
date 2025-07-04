import SwiftUI

struct CheckView: View {
    @StateObject var viewModel = CheckViewModel()
    @State private var isEditing = false
    @State private var balance: Double = 0
    @State var editingCurrency: String = "RUB"
    @FocusState private var balanceFieldIsFocused: Bool
    @State private var isCurrencyDialogPresented = false
    @State private var isBalanceHidden = false
    
    private var formattedBalance: String {
        let style = FloatingPointFormatStyle<Double>.number
            .precision(.fractionLength(0...2))
        let numberString = style.format(balance)
        return numberString + " " + currencySymbol(for: editingCurrency)
    }
    
    var body: some View {
        NavigationStack{
            
            VStack(alignment: .leading, spacing: 5) {
                
                Text("Мой счет")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal, 20)
                
                mainList
                
                ShakeDetector {
                    withAnimation {
                        isBalanceHidden.toggle()
                    }
                }
            }
            .background(Color(.systemGray6))
            .toolbar {
                toolBarSection
            }
            .gesture(
                DragGesture().onEnded { value in
                    if value.translation.height > 0 {
                        balanceFieldIsFocused = false
                    }
                }
            )
        }
        .refreshable {
            await viewModel.loadAccount()
        }
        
    }
    
    private var mainList: some View {
        
        List {
            balanceSection
                .listRowBackground(
                    isEditing
                    ? Color.white
                    : Color.accentColor
                )
            curencySection
                .listRowBackground(
                    isEditing
                    ? Color.white
                    : Color.accentColor.opacity(0.3)
                )
        }
        .listSectionSpacing(20)
        .listRowBackground(Color.clear)
        
    }
    func pasteFromClipboard() {
        if let clipboard = UIPasteboard.general.string {
            
            let cleaned = clipboard
                .filter { "0123456789.,".contains($0) }
                .replacingOccurrences(of: ",", with: ".")
            
            var components = cleaned.split(separator: ".")
            let joined: String
            if components.count > 1 {
                let whole = components.removeFirst()
                let decimal = components.joined()
                joined = "\(whole).\(decimal)"
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
    
    private var balanceSection: some View {
        Section() {
            HStack {
                Text("💰  Баланс")
                Spacer()
                if isEditing {
                    
                    TextField("", value: $balance, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($balanceFieldIsFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            balanceFieldIsFocused = false
                        }
                    
                    
                    
                } else {
                    if isBalanceHidden {
                        Text(formattedBalance)
                            .spoiler(isOn: $isBalanceHidden)
                    } else {
                        Text(formattedBalance)
                            .transition(.opacity)
                    }
                }
            }
            
            
            .contentShape(Rectangle())
            .onTapGesture {
                if isEditing {
                    balanceFieldIsFocused = true
                }
                
            }
            
            if isEditing {
                HStack {
                    Spacer()
                    Button("Вставить") {
                        pasteFromClipboard()
                    }
                    .foregroundColor(.blue)
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
                }
            }
        }
    }
    func currencySymbol(for code: String) -> String {
        switch code {
        case "RUB": return "₽"
        case "USD": return "$"
        case "EUR": return "€"
        default: return code
        }
    }
    
    
    private var curencySection: some View {
        Section() {
            HStack {
                Text("Валюта")
                Spacer()
                if isEditing {
                    Button(action: {
                        isCurrencyDialogPresented = true
                    }) {
                        HStack {
                            Text(currencySymbol(for: editingCurrency))
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .confirmationDialog("Валюта", isPresented: $isCurrencyDialogPresented, titleVisibility: .visible) {
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
    private var toolBarSection: some ToolbarContent {
        ToolbarItem {
            if isEditing {
                
                Button("Сохранить") {
                    isEditing = false
                }
                .foregroundColor(.blue)
                
                
            } else {
                Button("Редактировать") {
                    isEditing = true
                }
                .foregroundColor(.blue)
            }
        }
    }
}

#Preview {
    CheckView()
}
