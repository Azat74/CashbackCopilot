import SwiftUI

struct RootTabView: View {
    @State private var selectedTab: Tab = .home
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tag(Tab.home)
            .tabItem {
                Label("Главная", systemImage: "sparkles")
            }

            NavigationStack {
                WalletView()
            }
            .tag(Tab.wallet)
            .tabItem {
                Label("Кошелек", systemImage: "wallet.pass")
            }

            NavigationStack {
                if selectedTab == .history {
                    HistoryView()
                } else {
                    Color.clear
                        .accessibilityHidden(true)
                }
            }
            .tag(Tab.history)
            .tabItem {
                Label("История", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                SettingsView()
            }
            .tag(Tab.settings)
            .tabItem {
                Label("Настройки", systemImage: "gearshape")
            }
        }
        .fullScreenCover(isPresented: $appModel.isOnboardingPresented) {
            OnboardingView()
        }
    }
}

private extension RootTabView {
    enum Tab: Hashable {
        case home
        case wallet
        case history
        case settings
    }
}
