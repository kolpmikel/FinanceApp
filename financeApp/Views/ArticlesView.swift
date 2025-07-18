import SwiftUI

struct ArticlesView: View {
    @StateObject private var viewModel = ArticlesViewModel()
    private var circleColor: Color { Color("AccentColor").opacity(0.15) }
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    Section(header: Text("Статьи")) {
                        ForEach(viewModel.filteredCategories) { category in
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(circleColor)
                                        .frame(width: 32, height: 32)
                                    Text(String(category.emoji))
                                        .font(.system(size: 16))
                                }
                                Text(category.name)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .searchable(text: $viewModel.searchText, prompt: "Поиск по статьям")
                .navigationTitle("Мои статьи")
                .disabled(viewModel.isLoading)
                
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                }
            }
            .task {
                await viewModel.loadAll()
            }
            .alert(
                viewModel.errorMessage ?? "",
                isPresented: Binding<Bool>(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

#Preview {
    ArticlesView()
}
