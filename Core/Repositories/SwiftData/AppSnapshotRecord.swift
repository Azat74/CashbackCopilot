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

    static let demo = AppSnapshot(
        banks: [MockData.tBank, MockData.alfa],
        paymentMethods: MockData.methods,
        rules: MockData.rules,
        months: MockData.months,
        progress: MockData.progress,
        loggedPayments: []
    )
}

