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

    func testQrScannerParseFlow() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SMOKE")
        app.launch()

        let startButton = app.buttons["onboarding.startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let openScannerButton = app.buttons["home.openScannerButton"]
        XCTAssertTrue(openScannerButton.waitForExistence(timeout: 5))
        revealAndTap(openScannerButton, in: app)

        let payloadField = app.textFields["scanner.payloadField"]
        XCTAssertTrue(payloadField.waitForExistence(timeout: 5))
        XCTAssertEqual(payloadField.value as? String, "sbp://pay?merchant=АЗС Тест&sum=1500")

        let parseButton = app.buttons["scanner.parseButton"]
        XCTAssertTrue(parseButton.waitForExistence(timeout: 5))
        revealAndTap(parseButton, in: app)

        let channel = app.staticTexts["scanner.result.channel"]
        XCTAssertTrue(channel.waitForExistence(timeout: 5))
        XCTAssertEqual(channel.label, "Канал: СБП")

        let amount = app.staticTexts["scanner.result.amount"]
        XCTAssertTrue(amount.exists)
        XCTAssertTrue(amount.label.contains("Amount:"))
        XCTAssertTrue(amount.label.contains("1"))
        XCTAssertTrue(amount.label.contains("500"))
        XCTAssertTrue(amount.label.contains("₽"))

        let merchant = app.staticTexts["scanner.result.merchant"]
        XCTAssertTrue(merchant.exists)
        XCTAssertEqual(merchant.label, "Merchant: АЗС Тест")
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
