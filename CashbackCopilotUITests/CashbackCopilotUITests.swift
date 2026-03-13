import XCTest

@MainActor
final class CashbackCopilotUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    func testManualRecommendationHappyPath() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SMOKE")
        app.launch()

        let startButton = app.buttons["onboarding.startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let amountField = app.textFields["home.amountField"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 5))
        XCTAssertEqual(amountField.value as? String, "1500")

        let showRecommendationButton = app.buttons["home.showRecommendationButton"]
        XCTAssertTrue(showRecommendationButton.waitForExistence(timeout: 5))
        XCTAssertTrue(showRecommendationButton.isEnabled)
        revealAndTap(showRecommendationButton, in: app)

        let bestMethodName = app.staticTexts["recommendation.bestMethodName"]
        XCTAssertTrue(bestMethodName.waitForExistence(timeout: 5))

        let expectedReward = app.staticTexts["recommendation.expectedReward"]
        XCTAssertTrue(expectedReward.exists)

        let logPaymentButton = app.buttons["recommendation.logPaymentButton"]
        XCTAssertTrue(reveal(logPaymentButton, in: app))
        revealAndTap(logPaymentButton, in: app)

        let loggedPaymentMessage = app.staticTexts["recommendation.loggedPaymentMessage"]
        XCTAssertTrue(loggedPaymentMessage.waitForExistence(timeout: 5))
    }

    private func revealAndTap(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(reveal(element, in: app))
        XCTAssertTrue(element.isHittable)
        element.tap()
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        if element.waitForExistence(timeout: 1), element.isHittable {
            return true
        }

        for _ in 0..<5 {
            if app.keyboards.element.exists {
                app.swipeUp()
            } else {
                app.swipeUp()
            }

            if element.waitForExistence(timeout: 1), element.isHittable {
                return true
            }
        }

        return element.exists && element.isHittable
    }
}
