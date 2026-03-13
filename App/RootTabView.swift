import SwiftUI

struct RootTabView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Главная", systemImage: "sparkles")
            }

            NavigationStack {
                WalletView()
            }
            .tabItem {
                Label("Кошелек", systemImage: "wallet.pass")
            }

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("История", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Настройки", systemImage: "gearshape")
            }
        }
        .fullScreenCover(isPresented: $appModel.isOnboardingPresented) {
            OnboardingView()
        }
    }
}
