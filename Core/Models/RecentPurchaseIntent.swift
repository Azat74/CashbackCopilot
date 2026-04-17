import Foundation

struct RecentPurchaseIntent: Identifiable, Codable, Equatable, Hashable {
    let id: String

    var context: PurchaseContext
    var lastUsedAt: Date
    var useCount: Int

    init(context: PurchaseContext, lastUsedAt: Date, useCount: Int) {
        self.id = [
            context.category.rawValue,
            context.channel.rawValue,
            context.merchantName?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "",
            String(Int(context.amount.rounded()))
        ].joined(separator: "|")
        self.context = context
        self.lastUsedAt = lastUsedAt
        self.useCount = useCount
    }
}
