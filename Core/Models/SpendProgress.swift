import Foundation

struct SpendProgress: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let ruleId: UUID

    var monthKey: String
    var spentAmount: Double
    var rewardAccumulated: Double

    init(
        id: UUID = UUID(),
        ruleId: UUID,
        monthKey: String,
        spentAmount: Double = 0,
        rewardAccumulated: Double = 0
    ) {
        self.id = id
        self.ruleId = ruleId
        self.monthKey = monthKey
        self.spentAmount = spentAmount
        self.rewardAccumulated = rewardAccumulated
    }
}

