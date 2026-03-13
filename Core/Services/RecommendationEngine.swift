import Foundation

protocol RecommendationEngine {
    func recommend(
        for context: PurchaseContext,
        paymentMethods: [PaymentMethod],
        rules: [CashbackRule],
        progress: [SpendProgress]
    ) -> RecommendationResult
}

