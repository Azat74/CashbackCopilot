import Foundation

struct DefaultRecommendationEngine: RecommendationEngine {
    func recommend(
        for context: PurchaseContext,
        paymentMethods: [PaymentMethod],
        rules: [CashbackRule],
        progress: [SpendProgress]
    ) -> RecommendationResult {
        let activeMethodIDs = Set(paymentMethods.filter(\.isActive).map(\.id))

        let options = rules
            .filter { $0.isActive && activeMethodIDs.contains($0.paymentMethodId) }
            .filter { $0.category == context.category }
            .compactMap { buildOption(for: $0, context: context, progress: progress) }
            .sorted(by: compareOptions)

        return RecommendationResult(
            purchaseContextId: context.id,
            bestOption: options.first,
            alternatives: Array(options.dropFirst())
        )
    }

    private func buildOption(
        for rule: CashbackRule,
        context: PurchaseContext,
        progress: [SpendProgress]
    ) -> RecommendationOption? {
        guard isChannelSupported(rule: rule, channel: context.channel) else {
            return nil
        }

        if let minAmount = rule.minAmount, context.amount < minAmount {
            return nil
        }

        let usage = progress.first(where: { $0.ruleId == rule.id })
        let eligibleAmount = computeEligibleAmount(for: rule, usage: usage, purchaseAmount: context.amount)
        guard eligibleAmount > 0 else {
            return nil
        }

        let reward = computeReward(for: rule, eligibleAmount: eligibleAmount, usage: usage)
        guard reward >= 0 else {
            return nil
        }

        let confidence = min(max(context.confidence, 0), 1)
        let expectedPercent = context.amount > 0 ? (reward / context.amount) * 100 : 0

        var reasons = [
            "Категория подходит",
            channelReason(for: context.channel),
            "Лимит по правилу еще доступен"
        ]

        if let minAmount = rule.minAmount {
            reasons.append("Сумма проходит минимальный порог \(Int(minAmount)) ₽")
        }

        var risks: [String] = []

        if context.confidence < 1 {
            risks.append("Есть неопределенность в определении контекста покупки")
        }

        if context.source == .qr {
            risks.append("QR не гарантирует точную банковскую классификацию операции")
        }

        if context.merchantName == nil {
            risks.append("Merchant не распознан")
        }

        if rule.excludeIfMixedWithOtherPromo {
            risks.append("Правило может не сработать при смешении с другой акцией")
        }

        return RecommendationOption(
            paymentMethodId: rule.paymentMethodId,
            ruleId: rule.id,
            expectedReward: reward,
            expectedPercent: expectedPercent,
            confidence: confidence,
            reasons: reasons,
            risks: risks
        )
    }

    private func isChannelSupported(rule: CashbackRule, channel: PaymentChannel) -> Bool {
        switch channel {
        case .card:
            return true
        case .qr:
            return rule.qrAllowed
        case .sbp:
            return rule.sbpAllowed
        }
    }

    private func computeEligibleAmount(
        for rule: CashbackRule,
        usage: SpendProgress?,
        purchaseAmount: Double
    ) -> Double {
        guard purchaseAmount > 0 else {
            return 0
        }

        guard let spendCap = rule.monthlySpendCap else {
            return purchaseAmount
        }

        let spent = usage?.spentAmount ?? 0
        let remaining = max(0, spendCap - spent)
        return min(purchaseAmount, remaining)
    }

    private func computeReward(
        for rule: CashbackRule,
        eligibleAmount: Double,
        usage: SpendProgress?
    ) -> Double {
        let rawReward: Double

        if let fixedReward = rule.fixedReward {
            rawReward = eligibleAmount > 0 ? fixedReward : 0
        } else if let percent = rule.percent {
            rawReward = eligibleAmount * percent / 100
        } else {
            rawReward = 0
        }

        guard let rewardCap = rule.monthlyRewardCap else {
            return max(0, rawReward)
        }

        let consumed = usage?.rewardAccumulated ?? 0
        let remaining = max(0, rewardCap - consumed)
        return max(0, min(rawReward, remaining))
    }

    private func channelReason(for channel: PaymentChannel) -> String {
        switch channel {
        case .card:
            "Правило подходит для оплаты картой"
        case .qr:
            "Правило поддерживает оплату по QR"
        case .sbp:
            "Правило поддерживает оплату через СБП"
        }
    }

    private func compareOptions(lhs: RecommendationOption, rhs: RecommendationOption) -> Bool {
        if lhs.expectedReward != rhs.expectedReward {
            return lhs.expectedReward > rhs.expectedReward
        }

        if lhs.confidence != rhs.confidence {
            return lhs.confidence > rhs.confidence
        }

        return lhs.expectedPercent > rhs.expectedPercent
    }
}

