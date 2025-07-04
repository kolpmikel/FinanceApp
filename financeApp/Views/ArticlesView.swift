import SwiftUI

struct ArticlesView: View {
    @State private var searchText = ""
    @StateObject private var viewModel = ArticlesViewModel()
    private var circleColor: Color { Color("AccentColor").opacity(0.15) }
    
    private var filteredCategories: [Category] {
        guard !searchText.isEmpty else { return viewModel.categories }
        return viewModel.categories.filter { category in
            viewModel.fuzzyMatch(searchText, category.name)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Статьи")) {
                    ForEach(filteredCategories) { category in
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
            .searchable(text: $searchText, prompt: "Поиск по статьям")
            .navigationTitle("Мои статьи")
            .task {
                await viewModel.loadAll()
            }
        }
    }
}

#Preview {
    ArticlesView()
}

