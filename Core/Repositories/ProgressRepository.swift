import Foundation

protocol ProgressRepository {
    func fetchProgress() -> [SpendProgress]
}

