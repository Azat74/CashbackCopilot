import Foundation
import SwiftData

@MainActor
enum PreviewContainer {
    static let modelContainer: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: AppSnapshotRecord.self, configurations: configuration)
        let repository = LocalSnapshotRepository(context: container.mainContext)
        repository.seedIfNeeded(with: .demo)
        return container
    }()

    static let appModel: AppModel = {
        let repository = LocalSnapshotRepository(context: modelContainer.mainContext)
        repository.seedIfNeeded(with: .demo)
        return AppModel(repository: repository)
    }()
}

