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

    func recordPayment(for context: PurchaseContext, result: RecommendationResult, actualPaymentMethodID: UUID? = nil) {
        let usedRecommendedMethod = actualPaymentMethodID == nil || actualPaymentMethodID == result.bestOption?.paymentMethodId
        let chosenMethodID = actualPaymentMethodID ?? result.bestOption?.paymentMethodId

        let payment = LoggedPayment(
            purchaseContextId: context.id,
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

    func resetDemoData() {
        let demo = AppSnapshot.demo
        banks = demo.banks
        paymentMethods = demo.paymentMethods
        rules = demo.rules
        progress = demo.progress
        loggedPayments = demo.loggedPayments
        isOnboardingPresented = true
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
