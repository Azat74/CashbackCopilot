import Foundation

struct RecommendationOption: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let paymentMethodId: UUID
    let ruleId: UUID?

    var expectedReward: Double
    var expectedPercent: Double
    var confidence: Double
    var reasons: [String]
    var risks: [String]

    init(
        id: UUID = UUID(),
        paymentMethodId: UUID,
        ruleId: UUID? = nil,
        expectedReward: Double,
        expectedPercent: Double,
        confidence: Double,
        reasons: [String] = [],
        risks: [String] = []
    ) {
        self.id = id
        self.paymentMethodId = paymentMethodId
        self.ruleId = ruleId
        self.expectedReward = expectedReward
        self.expectedPercent = expectedPercent
        self.confidence = confidence
        self.reasons = reasons
        self.risks = risks
    }
}

