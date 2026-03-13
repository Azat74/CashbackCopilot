import Foundation

struct LoggedPayment: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let purchaseContextId: UUID

    var amount: Double
    var merchantName: String?
    var category: CashbackCategory
    var channel: PaymentChannel
    var recommendedPaymentMethodId: UUID?
    var actualPaymentMethodId: UUID?
    var expectedReward: Double?
    var actualReward: Double?
    var wasRecommendationUsed: Bool
    var cashbackMatchedExpectation: Bool?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        purchaseContextId: UUID,
        amount: Double,
        merchantName: String? = nil,
        category: CashbackCategory,
        channel: PaymentChannel,
        recommendedPaymentMethodId: UUID? = nil,
        actualPaymentMethodId: UUID? = nil,
        expectedReward: Double? = nil,
        actualReward: Double? = nil,
        wasRecommendationUsed: Bool,
        cashbackMatchedExpectation: Bool? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.purchaseContextId = purchaseContextId
        self.amount = amount
        self.merchantName = merchantName
        self.category = category
        self.channel = channel
        self.recommendedPaymentMethodId = recommendedPaymentMethodId
        self.actualPaymentMethodId = actualPaymentMethodId
        self.expectedReward = expectedReward
        self.actualReward = actualReward
        self.wasRecommendationUsed = wasRecommendationUsed
        self.cashbackMatchedExpectation = cashbackMatchedExpectation
        self.createdAt = createdAt
    }
}
