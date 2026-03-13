import Foundation

struct ProgressService {
    func updatedProgress(
        after purchaseAmount: Double,
        expectedReward: Double,
        for ruleID: UUID,
        monthKey: String,
        existing: [SpendProgress]
    ) -> [SpendProgress] {
        if let index = existing.firstIndex(where: { $0.ruleId == ruleID && $0.monthKey == monthKey }) {
            var updated = existing
            updated[index].spentAmount += purchaseAmount
            updated[index].rewardAccumulated += expectedReward
            return updated
        }

        return existing + [
            SpendProgress(
                ruleId: ruleID,
                monthKey: monthKey,
                spentAmount: purchaseAmount,
                rewardAccumulated: expectedReward
            )
        ]
    }

    func remainingRewardCap(for rule: CashbackRule, progress: SpendProgress?) -> Double? {
        guard let cap = rule.monthlyRewardCap else {
            return nil
        }

        return max(0, cap - (progress?.rewardAccumulated ?? 0))
    }

    func remainingSpendCap(for rule: CashbackRule, progress: SpendProgress?) -> Double? {
        guard let cap = rule.monthlySpendCap else {
            return nil
        }

        return max(0, cap - (progress?.spentAmount ?? 0))
    }
}

