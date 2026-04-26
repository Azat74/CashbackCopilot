import XCTest
@testable import CashbackCopilot

final class QuickLaunchRouteTests: XCTestCase {
    func testBuildsURLAndContextForCategoryRecommendation() throws {
        let route = QuickLaunchRoute(
            category: .fuel,
            amount: 1_500,
            merchantName: "АЗС",
            channel: .card
        )

        let parsedRoute = try XCTUnwrap(QuickLaunchRoute(url: route.url))

        XCTAssertEqual(parsedRoute, route)
        XCTAssertEqual(parsedRoute.context.category, .fuel)
        XCTAssertEqual(parsedRoute.context.amount, 1_500)
        XCTAssertEqual(parsedRoute.context.merchantName, "АЗС")
        XCTAssertEqual(parsedRoute.context.channel, .card)
        XCTAssertEqual(parsedRoute.context.confidence, 0.8)
    }

    func testUsesDefaultAmountAndCardChannelWhenOptionalQueryItemsAreMissing() throws {
        let url = try XCTUnwrap(URL(string: "cashbackcopilot://recommend?category=groceries"))

        let route = try XCTUnwrap(QuickLaunchRoute(url: url))

        XCTAssertEqual(route.category, .groceries)
        XCTAssertEqual(route.amount, QuickLaunchRoute.defaultAmount)
        XCTAssertEqual(route.channel, .card)
        XCTAssertNil(route.merchantName)
    }

    func testRejectsUnsupportedURLsAndInvalidAmounts() {
        XCTAssertNil(QuickLaunchRoute(url: URL(string: "https://example.com/recommend?category=fuel")!))
        XCTAssertNil(QuickLaunchRoute(url: URL(string: "cashbackcopilot://settings")!))
        XCTAssertNil(QuickLaunchRoute(url: URL(string: "cashbackcopilot://recommend?category=unknown")!))
        XCTAssertNil(QuickLaunchRoute(url: URL(string: "cashbackcopilot://recommend?category=fuel&amount=0")!))
    }

    func testQuickLaunchStoreConsumesSavedRouteOnce() {
        let route = QuickLaunchRoute(category: .taxi, amount: 700, channel: .sbp)

        QuickLaunchStore.savePendingRoute(route)

        XCTAssertEqual(QuickLaunchStore.consumePendingRoute(), route)
        XCTAssertNil(QuickLaunchStore.consumePendingRoute())
    }

    @MainActor
    func testAppModelConsumesPendingQuickLaunchContextOnce() {
        let appModel = AppModel()

        appModel.requestQuickRecommendation(from: QuickLaunchRoute(category: .cafes, amount: 900, channel: .qr))

        let context = appModel.consumePendingQuickLaunchContext()
        XCTAssertEqual(context?.category, .cafes)
        XCTAssertEqual(context?.amount, 900)
        XCTAssertEqual(context?.channel, .qr)
        XCTAssertNil(appModel.consumePendingQuickLaunchContext())
    }
}
