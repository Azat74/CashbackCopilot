import SwiftUI

@main
struct CashbackCopilotApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appModel)
        }
    }
}

