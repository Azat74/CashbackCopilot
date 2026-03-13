import Foundation
import Observation

@Observable
final class AppModel {
    private let engine: RecommendationEngine
    private let progressService: ProgressService

    var banks: [Bank]
    var paymentMethods: [PaymentMethod]
    var rules: [CashbackRule]
    var progress: [SpendProgress]
    var loggedPayments: [LoggedPayment]
    var isOnboardingPresented: Bool

    init(
        engine: RecommendationEngine = DefaultRecommendationEngine(),
        progressService: ProgressService = ProgressService(),
        banks: [Bank] = [MockData.tBank, MockData.alfa],
        paymentMethods: [PaymentMethod] = MockData.methods,
        rules: [CashbackRule] = MockData.rules,
        progress: [SpendProgress] = MockData.progress,
        loggedPayments: [LoggedPayment] = []
    ) {
        self.engine = engine
        self.progressService = progressService
        self.banks = banks
        self.paymentMethods = paymentMethods
        self.rules = rules
        self.progress = progress
        self.loggedPayments = loggedPayments
        self.isOnboardingPresented = true
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
            return
        }

        progress = progressService.updatedProgress(
            after: context.amount,
            expectedReward: result.bestOption?.expectedReward ?? 0,
            for: ruleID,
            monthKey: Self.monthKey(for: Date()),
            existing: progress
        )
    }

    func resetDemoData() {
        progress = MockData.progress
        loggedPayments = []
        isOnboardingPresented = true
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
}

