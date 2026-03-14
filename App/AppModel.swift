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

        let payment = LoggedPayment(
            purchaseContextId: context.id,
            amount: context.amount,
            merchantName: context.merchantName,
            source: context.source,
            category: context.category,
            channel: context.channel,
            recommendedPaymentMethodId: result.bestOption?.paymentMethodId,
            actualPaymentMethodId: chosenMethodID,
            expectedReward: result.bestOption?.expectedReward,
            actualReward: nil,
            wasRecommendationUsed: usedRecommendedMethod,
            cashbackMatchedExpectation: nil
        )

        loggedPayments.insert(payment, at: 0)

        guard let ruleID = result.bestOption?.ruleId, usedRecommendedMethod else {
            persistSnapshot()
            return
        }

        progress = progressService.updatedProgress(
            after: context.amount,
            expectedReward: result.bestOption?.expectedReward ?? 0,
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

    private static func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    private func persistSnapshot() {
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
