import XCTest

@MainActor
final class CashbackCopilotHomeSnapshotsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testQuickRecommendationSnapshotOpensRecommendation() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SMOKE")
        app.launch()

        let startButton = app.buttons["onboarding.startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let snapshotCard = app.buttons["home.quickSnapshot.fuel"]
        XCTAssertTrue(snapshotCard.waitForExistence(timeout: 5))
        XCTAssertTrue(reveal(snapshotCard, in: app))
        snapshotCard.tap()

        let bestMethodName = app.staticTexts["recommendation.bestMethodName"]
        XCTAssertTrue(bestMethodName.waitForExistence(timeout: 10))
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication, maxAttempts: Int = 5) -> Bool {
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
