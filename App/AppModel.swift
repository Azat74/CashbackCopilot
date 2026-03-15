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
    var months: [CashbackMonth]
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
        months: [CashbackMonth] = AppSnapshot.demo.months,
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
            months: months,
            progress: progress,
            loggedPayments: loggedPayments
        )
        self.banks = snapshot.banks
        self.paymentMethods = snapshot.paymentMethods
        self.rules = snapshot.rules
        self.months = snapshot.months
        self.progress = snapshot.progress
        self.loggedPayments = snapshot.loggedPayments
        self.isOnboardingPresented = true

        // Migrate existing data if months are empty
        let migratedSnapshot = Self.migrateIfNeeded(snapshot: AppSnapshot(
            banks: self.banks,
            paymentMethods: self.paymentMethods,
            rules: self.rules,
            months: self.months,
            progress: self.progress,
            loggedPayments: self.loggedPayments
        ))
        self.months = migratedSnapshot.months

        repository?.seedIfNeeded(with: migratedSnapshot)
    }

    func makeRecommendation(for context: PurchaseContext) -> RecommendationResult {
        let activeRules = activeRules(for: currentMonthKey)
        let currentProgress = progress.filter { $0.monthKey == currentMonthKey }

        return engine.recommend(
            for: context,
            paymentMethods: paymentMethods,
            rules: activeRules,
            progress: currentProgress
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
        guard let method = paymentMethods.first(where: { $0.id == rule.paymentMethodId }) else {
            return
        }

        rules.append(rule)

        // Add rule to current month for the bank
        let monthKey = currentMonthKey
        if let monthIndex = months.firstIndex(where: { $0.monthKey == monthKey && $0.bankId == method.bankId }) {
            let maxOrder = months[monthIndex].ruleStates.map(\.order).max() ?? -1
            months[monthIndex].ruleStates.append(RuleState(ruleId: rule.id, isActive: true, order: maxOrder + 1))
        } else {
            // Create new month for this bank if it doesn't exist
            let newMonth = CashbackMonth(
                bankId: method.bankId,
                monthKey: monthKey,
                ruleStates: [RuleState(ruleId: rule.id, isActive: true, order: 0)],
                source: .manual
            )
            months.append(newMonth)
        }

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
        months = demo.months
        progress = demo.progress
        loggedPayments = demo.loggedPayments
        replayOnboarding()
        persistSnapshot()
    }

    func resetLocalData() {
        banks = []
        paymentMethods = []
        rules = []
        months = []
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

    // MARK: - Month-scoped methods

    var currentMonthKey: String {
        Self.monthKey(for: Date())
    }

    func activeRules(for monthKey: String, bankId: UUID? = nil) -> [CashbackRule] {
        // Find months matching the criteria
        let matchingMonths = months.filter { month in
            month.monthKey == monthKey && (bankId == nil || month.bankId == bankId)
        }

        // If no months exist, fall back to all active rules for backward compatibility
        guard !matchingMonths.isEmpty else {
            return rules.filter { $0.isActive }
        }

        // Collect all active rule IDs from matching months
        let activeRuleIDs = Set(matchingMonths.flatMap { month in
            month.ruleStates.filter { $0.isActive }.map { $0.ruleId }
        })

        return rules.filter { activeRuleIDs.contains($0.id) }
    }

    func month(for monthKey: String, bankId: UUID) -> CashbackMonth? {
        months.first { $0.monthKey == monthKey && $0.bankId == bankId }
    }

    func months(for bankId: UUID) -> [CashbackMonth] {
        months
            .filter { $0.bankId == bankId }
            .sorted { $0.monthKey > $1.monthKey }
    }

    func createMonth(_ month: CashbackMonth) {
        guard banks.contains(where: { $0.id == month.bankId }) else {
            return
        }

        months.append(month)
        persistSnapshot()
    }

    func updateMonth(_ month: CashbackMonth) {
        guard let index = months.firstIndex(where: { $0.id == month.id }) else {
            return
        }

        months[index] = month
        persistSnapshot()
    }

    func setRuleActive(_ ruleId: UUID, active: Bool, inMonth monthKey: String, forBank bankId: UUID) {
        guard let monthIndex = months.firstIndex(where: { $0.monthKey == monthKey && $0.bankId == bankId }),
              let stateIndex = months[monthIndex].ruleStates.firstIndex(where: { $0.ruleId == ruleId }) else {
            return
        }

        months[monthIndex].ruleStates[stateIndex].isActive = active
        persistSnapshot()
    }

    // MARK: - Static Helpers (accessible to tests)

    static func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    static func migrateIfNeeded(snapshot: AppSnapshot) -> AppSnapshot {
        guard snapshot.months.isEmpty else { return snapshot }

        let currentMonthKey = monthKey(for: Date())

        // Group rules by bank via payment methods
        let bankPaymentMethods = Dictionary(grouping: snapshot.paymentMethods) { $0.bankId }
        var newMonths: [CashbackMonth] = []

        for (bankId, methods) in bankPaymentMethods {
            let methodIds = Set(methods.map(\.id))
            let bankRules = snapshot.rules.filter { methodIds.contains($0.paymentMethodId) }

            guard !bankRules.isEmpty else { continue }

            let ruleStates = bankRules.enumerated().map { index, rule in
                RuleState(ruleId: rule.id, isActive: rule.isActive, order: index)
            }

            let month = CashbackMonth(
                bankId: bankId,
                monthKey: currentMonthKey,
                ruleStates: ruleStates,
                source: .manual
            )
            newMonths.append(month)
        }

        return AppSnapshot(
            banks: snapshot.banks,
            paymentMethods: snapshot.paymentMethods,
            rules: snapshot.rules,
            months: newMonths,
            progress: snapshot.progress,
            loggedPayments: snapshot.loggedPayments
        )
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

        // Use rules and progress from the payment's month
        let paymentMonthKey = Self.monthKey(for: payment.createdAt)
        let activeRulesForPayment = activeRules(for: paymentMonthKey)
        let monthProgress = progress.filter { $0.monthKey == paymentMonthKey }

        let result = engine.recommend(
            for: context,
            paymentMethods: paymentMethods,
            rules: activeRulesForPayment,
            progress: monthProgress
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

    func persistSnapshot() {
        repository?.saveSnapshot(
            AppSnapshot(
                banks: banks,
                paymentMethods: paymentMethods,
                rules: rules,
                months: months,
                progress: progress,
                loggedPayments: loggedPayments
            )
        )
    }
}
