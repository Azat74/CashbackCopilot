import XCTest

@MainActor
final class CashbackCopilotHomeRecentIntentsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testRecentPurchaseIntentOpensRecommendation() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SMOKE")
        app.launchArguments.append("UITEST_RECENT_INTENTS")
        app.launch()

        startOnboarding(in: app)

        let recentIntent = app.buttons["home.recentIntent.fuel"]
        XCTAssertTrue(recentIntent.waitForExistence(timeout: 5))
        XCTAssertTrue(reveal(recentIntent, in: app))
        recentIntent.tap()

        let bestMethodName = app.staticTexts["recommendation.bestMethodName"]
        XCTAssertTrue(bestMethodName.waitForExistence(timeout: 10))
    }

    private func startOnboarding(in app: XCUIApplication) {
        let startButton = app.buttons["onboarding.startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication, maxAttempts: Int = 6) -> Bool {
        var attempts = 0
        while attempts < maxAttempts {
            if element.exists && element.isHittable {
                return true
            }

            app.swipeUp()
            attempts += 1
        }

        return element.exists && element.isHittable
    }
}
