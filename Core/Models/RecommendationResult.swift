import Foundation

struct RecommendationResult: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let purchaseContextId: UUID

    var bestOption: RecommendationOption?
    var alternatives: [RecommendationOption]
    var createdAt: Date

    var hasRecommendation: Bool {
        bestOption != nil
    }

    init(
        id: UUID = UUID(),
        purchaseContextId: UUID,
        bestOption: RecommendationOption?,
        alternatives: [RecommendationOption] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.purchaseContextId = purchaseContextId
        self.bestOption = bestOption
        self.alternatives = alternatives
        self.createdAt = createdAt
    }
}

