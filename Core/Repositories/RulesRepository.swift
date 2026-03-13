import Foundation

protocol RulesRepository {
    func fetchRules() -> [CashbackRule]
}

