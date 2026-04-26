import SwiftUI

struct RootTabView: View {
    @Environment(\.scenePhase) private var scenePhase
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
        .task {
            consumePendingQuickLaunchRouteIfNeeded()
        }
        .onOpenURL { url in
            guard let route = QuickLaunchRoute(url: url) else {
                return
            }

            selectedTab = .home
            appModel.requestQuickRecommendation(from: route)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            consumePendingQuickLaunchRouteIfNeeded()
        }
    }

    private func consumePendingQuickLaunchRouteIfNeeded() {
        guard let route = QuickLaunchStore.consumePendingRoute() else {
            return
        }

        selectedTab = .home
        appModel.requestQuickRecommendation(from: route)
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
