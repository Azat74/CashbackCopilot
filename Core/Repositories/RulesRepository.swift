import Foundation

@MainActor
protocol RulesRepository {
    func fetchRules() -> [CashbackRule]
}
