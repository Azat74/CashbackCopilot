import Foundation

enum CashbackConfirmationStatus: Equatable {
    case pending
    case matched
    case mismatched

    var displayName: String {
        switch self {
        case .pending:
            "Ожидает подтверждения"
        case .matched:
            "Совпало"
        case .mismatched:
            "Не совпало"
        }
    }
}

struct LoggedPayment: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let purchaseContextId: UUID

    var amount: Double
    var merchantName: String?
    var source: PurchaseSource
    var category: CashbackCategory
    var channel: PaymentChannel
    var recommendedPaymentMethodId: UUID?
    var actualPaymentMethodId: UUID?
    var expectedReward: Double?
    var actualReward: Double?
    var wasRecommendationUsed: Bool
    var cashbackMatchedExpectation: Bool?
    var appliedRuleId: UUID?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        purchaseContextId: UUID,
        amount: Double,
        merchantName: String? = nil,
        source: PurchaseSource,
        category: CashbackCategory,
        channel: PaymentChannel,
        recommendedPaymentMethodId: UUID? = nil,
        actualPaymentMethodId: UUID? = nil,
        expectedReward: Double? = nil,
        actualReward: Double? = nil,
        wasRecommendationUsed: Bool,
        cashbackMatchedExpectation: Bool? = nil,
        appliedRuleId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.purchaseContextId = purchaseContextId
        self.amount = amount
        self.merchantName = merchantName
        self.source = source
        self.category = category
        self.channel = channel
        self.recommendedPaymentMethodId = recommendedPaymentMethodId
        self.actualPaymentMethodId = actualPaymentMethodId
        self.expectedReward = expectedReward
        self.actualReward = actualReward
        self.wasRecommendationUsed = wasRecommendationUsed
        self.cashbackMatchedExpectation = cashbackMatchedExpectation
        self.appliedRuleId = appliedRuleId
        self.createdAt = createdAt
    }

    var confirmationStatus: CashbackConfirmationStatus {
        guard actualReward != nil else {
            return .pending
        }

        if cashbackMatchedExpectation == true {
            return .matched
        }

        return .mismatched
    }
}
