import XCTest
@testable import CashbackCopilot

@MainActor
final class AppModelRecentPurchaseIntentTests: XCTestCase {
    func testRecentPurchaseIntentsAreBuiltFromLoggedPayments() throws {
        let recentDate = Date()
        let olderDate = Date(timeIntervalSinceNow: -3_600)
        let fuelPayment = loggedPayment(category: .fuel, merchantName: "АЗС", amount: 1_500, createdAt: recentDate)
        let groceryPayment = loggedPayment(category: .groceries, merchantName: "Маркет", amount: 2_000, createdAt: olderDate)
        let appModel = AppModel(
            repository: nil,
            banks: [],
            paymentMethods: [],
            rules: [],
            progress: [],
            loggedPayments: [groceryPayment, fuelPayment]
        )

        let intents = appModel.recentPurchaseIntents()

        XCTAssertEqual(intents.map(\.context.category), [.fuel, .groceries])
        XCTAssertEqual(intents.first?.context.merchantName, "АЗС")
        XCTAssertEqual(intents.first?.context.amount, 1_500)
    }

    func testRecentPurchaseIntentsDeduplicateRepeatedContexts() throws {
        let firstPayment = loggedPayment(category: .fuel, merchantName: "АЗС", amount: 1_500, createdAt: Date())
        let repeatedPayment = loggedPayment(
            category: .fuel,
            merchantName: "АЗС",
            amount: 1_500,
            createdAt: Date(timeIntervalSinceNow: -60)
        )
        let appModel = AppModel(
            repository: nil,
            banks: [],
            paymentMethods: [],
            rules: [],
            progress: [],
            loggedPayments: [firstPayment, repeatedPayment]
        )

        let intent = try XCTUnwrap(appModel.recentPurchaseIntents().first)

        XCTAssertEqual(appModel.recentPurchaseIntents().count, 1)
        XCTAssertEqual(intent.useCount, 2)
        XCTAssertEqual(intent.context.category, .fuel)
    }

    func testRecentPurchaseIntentsRespectLimit() {
        let payments = CashbackCategory.allCases.enumerated().map { index, category in
            loggedPayment(
                category: category,
                merchantName: category.displayName,
                amount: Double(index + 1) * 100,
                createdAt: Date(timeIntervalSinceNow: Double(-index))
            )
        }
        let appModel = AppModel(
            repository: nil,
            banks: [],
            paymentMethods: [],
            rules: [],
            progress: [],
            loggedPayments: payments
        )

        XCTAssertEqual(appModel.recentPurchaseIntents(limit: 3).count, 3)
    }

    func testRecentPurchaseIntentsUseFreshRecommendationContextId() throws {
        let purchaseContextId = UUID()
        let payment = loggedPayment(
            purchaseContextId: purchaseContextId,
            category: .fuel,
            merchantName: "АЗС",
            amount: 1_500,
            createdAt: Date()
        )
        let appModel = AppModel(
            repository: nil,
            banks: [],
            paymentMethods: [],
            rules: [],
            progress: [],
            loggedPayments: [payment]
        )

        let intent = try XCTUnwrap(appModel.recentPurchaseIntents().first)

        XCTAssertNotEqual(intent.context.id, purchaseContextId)
    }

    private func loggedPayment(
        purchaseContextId: UUID = UUID(),
        category: CashbackCategory,
        merchantName: String?,
        amount: Double,
        createdAt: Date
    ) -> LoggedPayment {
        LoggedPayment(
            purchaseContextId: purchaseContextId,
            amount: amount,
            merchantName: merchantName,
            source: .manual,
            category: category,
            channel: .card,
            recommendedPaymentMethodId: nil,
            actualPaymentMethodId: nil,
            expectedReward: nil,
            actualReward: nil,
            wasRecommendationUsed: false,
            createdAt: createdAt
        )
    }
}
