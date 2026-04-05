import Foundation

struct QuickRecommendationSnapshot: Identifiable, Codable, Equatable, Hashable {
    let id: String

    var category: CashbackCategory
    var context: PurchaseContext
    var paymentMethodId: UUID
    var expectedReward: Double
    var expectedPercent: Double
    var confidence: Double

    init(
        category: CashbackCategory,
        context: PurchaseContext,
        paymentMethodId: UUID,
        expectedReward: Double,
        expectedPercent: Double,
        confidence: Double
    ) {
        self.id = "\(category.rawValue)-\(context.channel.rawValue)"
        self.category = category
        self.context = context
        self.paymentMethodId = paymentMethodId
        self.expectedReward = expectedReward
        self.expectedPercent = expectedPercent
        self.confidence = confidence
    }
}
