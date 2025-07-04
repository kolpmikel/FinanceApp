import SwiftUI

struct TabBarView: View {
    init() {
          let appearance = UITabBarAppearance()
          appearance.configureWithOpaqueBackground()
          appearance.backgroundColor = .white

          UITabBar.appearance().standardAppearance = appearance
          if #available(iOS 15.0, *) {
              UITabBar.appearance().scrollEdgeAppearance = appearance
          }
      }
    
    var body: some View {
        TabView {
            
            TransactionsListView(direction: .outcome)
                .tabItem {
                    Image("Expenses"); Text("Расходы")
                }
            
            TransactionsListView(direction: .income)
                .tabItem {
                    Image("Income"); Text("Доходы")
                }
            
            CheckView()
                .tabItem {
                    Image("Check")
                    Text("Счет")
                }
            
            ArticlesView()
                .tabItem {
                    Image("Articles")
                    Text("Статьи")
                }
            
            SettingsView()
                .tabItem {
                    Image("Settings")
                    Text("Настройки")
                }
        }
    }
}

#Preview {
    TabBarView()
}

