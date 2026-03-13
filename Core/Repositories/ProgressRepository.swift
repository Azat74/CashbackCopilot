import Foundation

@MainActor
protocol ProgressRepository {
    func fetchProgress() -> [SpendProgress]
}
