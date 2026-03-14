import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private let repository: LocalSnapshotRepository?
    private let engine: RecommendationEngine
    private let progressService: ProgressService

    var banks: [Bank]
    var paymentMethods: [PaymentMethod]
    var rules: [CashbackRule]
    var progress: [SpendProgress]
    var loggedPayments: [LoggedPayment]
    var isOnboardingPresented: Bool

    init(
        repository: LocalSnapshotRepository? = nil,
        engine: RecommendationEngine = DefaultRecommendationEngine(),
        progressService: ProgressService = ProgressService(),
        banks: [Bank] = AppSnapshot.demo.banks,
        paymentMethods: [PaymentMethod] = AppSnapshot.demo.paymentMethods,
        rules: [CashbackRule] = AppSnapshot.demo.rules,
        progress: [SpendProgress] = AppSnapshot.demo.progress,
        loggedPayments: [LoggedPayment] = AppSnapshot.demo.loggedPayments
    ) {
        self.repository = repository
        self.engine = engine
        self.progressService = progressService
        let snapshot = repository?.loadSnapshot() ?? AppSnapshot(
            banks: banks,
            paymentMethods: paymentMethods,
            rules: rules,
            progress: progress,
            loggedPayments: loggedPayments
        )
        self.banks = snapshot.banks
        self.paymentMethods = snapshot.paymentMethods
        self.rules = snapshot.rules
        self.progress = snapshot.progress
        self.loggedPayments = snapshot.loggedPayments
        self.isOnboardingPresented = true
        repository?.seedIfNeeded(with: snapshot)
    }

    func makeRecommendation(for context: PurchaseContext) -> RecommendationResult {
        engine.recommend(
            for: context,
            paymentMethods: paymentMethods,
            rules: rules,
            progress: progress
        )
    }

    func paymentMethods(for bankID: UUID) -> [PaymentMethod] {
        paymentMethods
            .filter { $0.bankId == bankID }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    func rules(for paymentMethodID: UUID) -> [CashbackRule] {
        rules
            .filter { $0.paymentMethodId == paymentMethodID }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func addBank(name: String, iconName: String? = nil) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return
        }

        banks.append(Bank(name: trimmedName, iconName: iconName))
        banks.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        persistSnapshot()
    }

    func deleteBank(id: UUID) {
        let removedMethodIDs = Set(paymentMethods(for: id).map(\.id))
        let removedRuleIDs = Set(rules.filter { removedMethodIDs.contains($0.paymentMethodId) }.map(\.id))

        banks.removeAll { $0.id == id }
        paymentMethods.removeAll { $0.bankId == id }
        rules.removeAll { removedMethodIDs.contains($0.paymentMethodId) }
        progress.removeAll { removedRuleIDs.contains($0.ruleId) }
        persistSnapshot()
    }

    func addPaymentMethod(
        bankID: UUID,
        displayName: String,
        type: PaymentMethodType,
        last4: String? = nil
    ) {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast4 = last4?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, banks.contains(where: { $0.id == bankID }) else {
            return
        }

        paymentMethods.append(
            PaymentMethod(
                bankId: bankID,
                displayName: trimmedName,
                type: type,
                last4: trimmedLast4?.isEmpty == true ? nil : trimmedLast4
            )
        )
        persistSnapshot()
    }

    func deletePaymentMethod(id: UUID) {
        let removedRuleIDs = Set(rules.filter { $0.paymentMethodId == id }.map(\.id))

        paymentMethods.removeAll { $0.id == id }
        rules.removeAll { $0.paymentMethodId == id }
        progress.removeAll { removedRuleIDs.contains($0.ruleId) }
        persistSnapshot()
    }

    func addRule(_ rule: CashbackRule) {
        guard paymentMethods.contains(where: { $0.id == rule.paymentMethodId }) else {
            return
        }

        rules.append(rule)
        persistSnapshot()
    }

    func deleteRule(id: UUID) {
        rules.removeAll { $0.id == id }
        progress.removeAll { $0.ruleId == id }
        persistSnapshot()
    }

    func recordPayment(for context: PurchaseContext, result: RecommendationResult, actualPaymentMethodID: UUID? = nil) {
        let usedRecommendedMethod = actualPaymentMethodID == nil || actualPaymentMethodID == result.bestOption?.paymentMethodId
        let chosenMethodID = actualPaymentMethodID ?? result.bestOption?.paymentMethodId
        let chosenOption = recommendationOption(in: result, paymentMethodID: chosenMethodID)

        let payment = LoggedPayment(
            purchaseContextId: context.id,
            amount: context.amount,
            merchantName: context.merchantName,
            source: context.source,
            category: context.category,
            channel: context.channel,
            recommendedPaymentMethodId: result.bestOption?.paymentMethodId,
            actualPaymentMethodId: chosenMethodID,
            expectedReward: chosenOption?.expectedReward ?? fallbackExpectedReward(for: chosenMethodID),
            actualReward: nil,
            wasRecommendationUsed: usedRecommendedMethod,
            cashbackMatchedExpectation: nil,
            appliedRuleId: chosenOption?.ruleId
        )

        loggedPayments.insert(payment, at: 0)

        guard let chosenOption, let ruleID = chosenOption.ruleId else {
            persistSnapshot()
            return
        }

        progress = progressService.updatedProgress(
            after: context.amount,
            expectedReward: chosenOption.expectedReward,
            for: ruleID,
            monthKey: Self.monthKey(for: Date()),
            existing: progress
        )
        persistSnapshot()
    }

    func recommendationPaymentMethodIDs(for result: RecommendationResult) -> [UUID] {
        var seen: Set<UUID> = []
        let orderedOptions = [result.bestOption].compactMap { $0 } + result.alternatives

        return orderedOptions.compactMap { option in
            guard seen.insert(option.paymentMethodId).inserted else {
                return nil
            }

            return option.paymentMethodId
        }
    }

    func confirmActualCashback(for paymentID: UUID, amount: Double) {
        guard amount >= 0,
              let index = loggedPayments.firstIndex(where: { $0.id == paymentID }) else {
            return
        }

        var updatedPayment = loggedPayments[index]
        let expected = updatedPayment.expectedReward
        let matchedExpectation = expected.map { abs($0 - amount) < 0.01 }

        updatedPayment.actualReward = amount
        updatedPayment.cashbackMatchedExpectation = matchedExpectation

        var updatedPayments = loggedPayments
        updatedPayments[index] = updatedPayment
        loggedPayments = updatedPayments
        persistSnapshot()
    }

    func reviewLoggedPayment(
        for paymentID: UUID,
        category: CashbackCategory,
        actualPaymentMethodID: UUID?,
        actualReward amount: Double
    ) {
        guard amount >= 0,
              let index = loggedPayments.firstIndex(where: { $0.id == paymentID }) else {
            return
        }

        let previousPayment = loggedPayments[index]
        progress = progressRemovingContribution(of: previousPayment, from: progress)

        var updatedPayment = previousPayment
        updatedPayment.category = category
        updatedPayment.actualPaymentMethodId = actualPaymentMethodID
        updatedPayment.wasRecommendationUsed = updatedPayment.actualPaymentMethodId == updatedPayment.recommendedPaymentMethodId

        let option = recommendationOption(
            for: updatedPayment,
            category: category,
            actualPaymentMethodID: actualPaymentMethodID,
            progress: progress
        )

        updatedPayment.expectedReward = option?.expectedReward ?? fallbackExpectedReward(
            for: actualPaymentMethodID,
            existingReward: previousPayment.expectedReward
        )
        updatedPayment.appliedRuleId = option?.ruleId
        updatedPayment.actualReward = amount
        updatedPayment.cashbackMatchedExpectation = updatedPayment.expectedReward.map { abs($0 - amount) < 0.01 }

        var updatedPayments = loggedPayments
        updatedPayments[index] = updatedPayment
        loggedPayments = updatedPayments

        if let appliedRuleId = updatedPayment.appliedRuleId,
           let expectedReward = updatedPayment.expectedReward {
            progress = progressService.updatedProgress(
                after: updatedPayment.amount,
                expectedReward: expectedReward,
                for: appliedRuleId,
                monthKey: Self.monthKey(for: updatedPayment.createdAt),
                existing: progress
            )
        }

        persistSnapshot()
    }

    func expectedRewardPreview(
        for payment: LoggedPayment,
        category: CashbackCategory,
        actualPaymentMethodID: UUID?
    ) -> Double? {
        let adjustedProgress = progressRemovingContribution(of: payment, from: progress)
        let option = recommendationOption(
            for: payment,
            category: category,
            actualPaymentMethodID: actualPaymentMethodID,
            progress: adjustedProgress
        )

        return option?.expectedReward ?? fallbackExpectedReward(
            for: actualPaymentMethodID,
            existingReward: payment.expectedReward
        )
    }

    func replayOnboarding() {
        isOnboardingPresented = true
    }

    func restoreDemoData() {
        let demo = AppSnapshot.demo
        banks = demo.banks
        paymentMethods = demo.paymentMethods
        rules = demo.rules
        progress = demo.progress
        loggedPayments = demo.loggedPayments
        replayOnboarding()
        persistSnapshot()
    }

    func resetLocalData() {
        banks = []
        paymentMethods = []
        rules = []
        progress = []
        loggedPayments = []
        replayOnboarding()
        persistSnapshot()
    }

    func paymentMethodName(for id: UUID?) -> String {
        guard let id, let method = paymentMethods.first(where: { $0.id == id }) else {
            return "Неизвестно"
        }

        if let bank = banks.first(where: { $0.id == method.bankId }) {
            return "\(bank.name) · \(method.displayName)"
        }

        return method.displayName
    }

    func bankName(for paymentMethodID: UUID) -> String {
        guard let method = paymentMethods.first(where: { $0.id == paymentMethodID }),
              let bank = banks.first(where: { $0.id == method.bankId }) else {
            return "Банк"
        }

        return bank.name
    }

    func bank(for paymentMethodID: UUID) -> Bank? {
        guard let method = paymentMethods.first(where: { $0.id == paymentMethodID }) else {
            return nil
        }

        return banks.first { $0.id == method.bankId }
    }

}

private extension AppModel {
    func recommendationOption(in result: RecommendationResult, paymentMethodID: UUID?) -> RecommendationOption? {
        guard let paymentMethodID else {
            return nil
        }

        let options = [result.bestOption].compactMap { $0 } + result.alternatives
        return options.first { $0.paymentMethodId == paymentMethodID }
    }

    func recommendationOption(
        for payment: LoggedPayment,
        category: CashbackCategory,
        actualPaymentMethodID: UUID?,
        progress: [SpendProgress]
    ) -> RecommendationOption? {
        guard let actualPaymentMethodID else {
            return nil
        }

        let context = PurchaseContext(
            id: payment.purchaseContextId,
            source: payment.source,
            amount: payment.amount,
            merchantName: payment.merchantName,
            category: category,
            channel: payment.channel,
            confidence: 1,
            createdAt: payment.createdAt
        )

        let result = engine.recommend(
            for: context,
            paymentMethods: paymentMethods,
            rules: rules,
            progress: progress
        )

        let options = [result.bestOption].compactMap { $0 } + result.alternatives
        if let option = options.first(where: { $0.paymentMethodId == actualPaymentMethodID }) {
            return option
        }

        guard paymentMethods.contains(where: { $0.id == actualPaymentMethodID }) else {
            return nil
        }

        return RecommendationOption(
            paymentMethodId: actualPaymentMethodID,
            ruleId: nil,
            expectedReward: 0,
            expectedPercent: 0,
            confidence: 1,
            reasons: [],
            risks: []
        )
    }

    func progressRemovingContribution(
        of payment: LoggedPayment,
        from existing: [SpendProgress]
    ) -> [SpendProgress] {
        guard let appliedRuleId = payment.appliedRuleId,
              let expectedReward = payment.expectedReward else {
            return existing
        }

        return progressService.removingProgress(
            after: payment.amount,
            expectedReward: expectedReward,
            for: appliedRuleId,
            monthKey: Self.monthKey(for: payment.createdAt),
            existing: existing
        )
    }

    func fallbackExpectedReward(for paymentMethodID: UUID?) -> Double? {
        guard let paymentMethodID else {
            return nil
        }

        guard paymentMethods.contains(where: { $0.id == paymentMethodID }) else {
            return nil
        }

        return 0
    }

    func fallbackExpectedReward(for paymentMethodID: UUID?, existingReward: Double?) -> Double? {
        fallbackExpectedReward(for: paymentMethodID) ?? existingReward
    }

    static func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    func persistSnapshot() {
        repository?.saveSnapshot(
            AppSnapshot(
                banks: banks,
                paymentMethods: paymentMethods,
                rules: rules,
                progress: progress,
                loggedPayments: loggedPayments
            )
        )
    }
}
