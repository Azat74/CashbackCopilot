import SwiftUI
import SwiftData

@main
struct CashbackCopilotApp: App {
    private let sharedModelContainer: ModelContainer
    @State private var appModel: AppModel

    init() {
        let schema = Schema([AppSnapshotRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let repository = LocalSnapshotRepository(context: container.mainContext)
        repository.seedIfNeeded(with: .demo)
        self.sharedModelContainer = container
        _appModel = State(initialValue: AppModel(repository: repository))
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(appModel)
                .modelContainer(sharedModelContainer)
        }
    }
}
