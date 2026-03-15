import Foundation
import SwiftData

@Model
final class AppSnapshotRecord {
    @Attribute(.unique) var key: String
    var payload: Data
    var updatedAt: Date

    init(key: String = "default", payload: Data, updatedAt: Date = .now) {
        self.key = key
        self.payload = payload
        self.updatedAt = updatedAt
    }
}

struct AppSnapshot: Codable {
    var banks: [Bank]
    var paymentMethods: [PaymentMethod]
    var rules: [CashbackRule]
    var months: [CashbackMonth]
    var progress: [SpendProgress]
    var loggedPayments: [LoggedPayment]

    enum CodingKeys: String, CodingKey {
        case banks, paymentMethods, rules, months, progress, loggedPayments
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        banks = try container.decode([Bank].self, forKey: .banks)
        paymentMethods = try container.decode([PaymentMethod].self, forKey: .paymentMethods)
        rules = try container.decode([CashbackRule].self, forKey: .rules)
        // Backward compatibility: default to empty array for legacy snapshots without months
        months = (try? container.decode([CashbackMonth].self, forKey: .months)) ?? []
        progress = try container.decode([SpendProgress].self, forKey: .progress)
        loggedPayments = try container.decode([LoggedPayment].self, forKey: .loggedPayments)
    }

    init(
        banks: [Bank],
        paymentMethods: [PaymentMethod],
        rules: [CashbackRule],
        months: [CashbackMonth],
        progress: [SpendProgress],
        loggedPayments: [LoggedPayment]
    ) {
        self.banks = banks
        self.paymentMethods = paymentMethods
        self.rules = rules
        self.months = months
        self.progress = progress
        self.loggedPayments = loggedPayments
    }

    static let demo = AppSnapshot(
        banks: [MockData.tBank, MockData.alfa],
        paymentMethods: MockData.methods,
        rules: MockData.rules,
        months: MockData.months,
        progress: MockData.progress,
        loggedPayments: []
    )
}

