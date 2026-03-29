import Foundation

struct ParsedRuleDraft: Identifiable, Codable, Equatable, Hashable {
    let id: UUID

    var title: String
    var category: CashbackCategory
    var percent: Double?
    var fixedReward: Double?
    var needsReview: Bool
    var sourceScreenshotTitle: String
    var sourceLine: String

    init(
        id: UUID = UUID(),
        title: String,
        category: CashbackCategory,
        percent: Double? = nil,
        fixedReward: Double? = nil,
        needsReview: Bool = false,
        sourceScreenshotTitle: String,
        sourceLine: String
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.percent = percent
        self.fixedReward = fixedReward
        self.needsReview = needsReview
        self.sourceScreenshotTitle = sourceScreenshotTitle
        self.sourceLine = sourceLine
    }
}

struct ParsedCashbackDraft: Identifiable, Codable, Equatable, Hashable {
    let id: UUID

    var bankId: UUID
    var bankName: String
    var sourceScreenshotsCount: Int
    var rules: [ParsedRuleDraft]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        bankId: UUID,
        bankName: String,
        sourceScreenshotsCount: Int,
        rules: [ParsedRuleDraft],
        createdAt: Date = .now
    ) {
        self.id = id
        self.bankId = bankId
        self.bankName = bankName
        self.sourceScreenshotsCount = sourceScreenshotsCount
        self.rules = rules
        self.createdAt = createdAt
    }
}
