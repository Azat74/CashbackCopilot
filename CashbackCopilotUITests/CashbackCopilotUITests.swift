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

        assertRecommendationAndLogPayment(in: app)
    }

    func testQrScannerConfirmRecommendationFlow() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SMOKE")
        app.launch()

        startOnboarding(in: app)

        let openScannerButton = app.buttons["home.openScannerButton"]
        XCTAssertTrue(openScannerButton.waitForExistence(timeout: 5))
        revealAndTap(openScannerButton, in: app)

        assertParsedQrPayload(in: app)
        proceedThroughConfirmedQrContext(in: app)
        assertRecommendationAndLogPayment(in: app)
    }

    func testConfirmActualCashbackFromHistory() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SMOKE")
        app.launch()

        startOnboarding(in: app)
        createLoggedPayment(in: app)

        app.tabBars.buttons["История"].tap()

        let confirmCashbackButton = app.buttons["Подтвердить фактический кешбэк"].firstMatch
        XCTAssertTrue(confirmCashbackButton.waitForExistence(timeout: 5))
        revealAndTap(confirmCashbackButton, in: app)

        let amountField = app.textFields["confirmActualCashback.amountField"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 5))
        amountField.tap()
        amountField.typeText("75")

        let saveButton = app.buttons["confirmActualCashback.saveButton"]
        XCTAssertTrue(saveButton.exists)
        saveButton.tap()

        XCTAssertFalse(amountField.waitForExistence(timeout: 1))

        let editCashbackButton = app.buttons["Изменить фактический кешбэк"].firstMatch
        XCTAssertTrue(editCashbackButton.waitForExistence(timeout: 5))
    }

    func testSettingsCanWipeLocalData() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SMOKE")
        app.launch()

        startOnboarding(in: app)

        app.tabBars.buttons["Настройки"].tap()

        let wipeButton = app.buttons["settings.wipeLocalDataButton"]
        revealAndTap(wipeButton, in: app)

        let confirmButton = app.alerts.buttons["Удалить"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()

        let startButton = app.buttons["onboarding.startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        app.tabBars.buttons["Главная"].tap()

        let missingMethodsMessage = app.staticTexts["home.missingPaymentMethodsMessage"]
        XCTAssertTrue(missingMethodsMessage.waitForExistence(timeout: 5))

        let missingRulesMessage = app.staticTexts["home.missingRulesMessage"]
        XCTAssertTrue(missingRulesMessage.exists)

        let showRecommendationButton = app.buttons["home.showRecommendationButton"]
        XCTAssertTrue(showRecommendationButton.exists)
        XCTAssertFalse(showRecommendationButton.isEnabled)

        app.tabBars.buttons["История"].tap()
        XCTAssertTrue(app.staticTexts["История пока пуста"].waitForExistence(timeout: 5))
    }

    private func startOnboarding(in app: XCUIApplication) {
        let startButton = app.buttons["onboarding.startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()
    }

    private func assertParsedQrPayload(in app: XCUIApplication) {
        let payloadField = payloadField(in: app)
        XCTAssertTrue(payloadField.waitForExistence(timeout: 5))
        XCTAssertEqual(payloadField.value as? String, "sbp://pay?merchant=АЗС Тест&sum=1500")

        let parseButton = app.buttons["scanner.parseButton"]
        XCTAssertTrue(parseButton.waitForExistence(timeout: 5))
        revealAndTap(parseButton, in: app)

        let channel = app.staticTexts["scanner.result.channel"]
        XCTAssertTrue(channel.waitForExistence(timeout: 5))
        XCTAssertEqual(channel.label, "Канал: СБП")

        let category = app.staticTexts["scanner.result.category"]
        XCTAssertTrue(category.exists)
        XCTAssertEqual(category.label, "Категория: АЗС")

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

    private func proceedThroughConfirmedQrContext(in app: XCUIApplication) {
        let continueButton = app.buttons["scanner.continueButton"]
        revealAndTap(continueButton, in: app)

        let confirmAmountField = app.textFields["confirm.amountField"]
        XCTAssertTrue(confirmAmountField.waitForExistence(timeout: 5))
        XCTAssertEqual(confirmAmountField.value as? String, "1500")

        let confirmMerchantField = app.textFields["confirm.merchantField"]
        XCTAssertTrue(confirmMerchantField.exists)
        XCTAssertEqual(confirmMerchantField.value as? String, "АЗС Тест")

        let confidenceBand = app.staticTexts["confirm.detectedConfidenceBand"]
        XCTAssertTrue(confidenceBand.exists)
        XCTAssertTrue(confidenceBand.label.contains("Высокая"))

        let firstHeuristic = app.staticTexts["confirm.heuristic.0"]
        XCTAssertTrue(firstHeuristic.exists)

        let confirmButton = app.buttons["confirm.showRecommendationButton"]
        XCTAssertTrue(reveal(confirmButton, in: app))
        XCTAssertTrue(confirmButton.isEnabled)
        revealAndTap(confirmButton, in: app)
    }

    private func assertRecommendationAndLogPayment(in app: XCUIApplication) {
        let bestMethodName = app.staticTexts["recommendation.bestMethodName"]
        XCTAssertTrue(bestMethodName.waitForExistence(timeout: 15))

        let expectedReward = app.staticTexts["recommendation.expectedReward"]
        XCTAssertTrue(expectedReward.exists)

        let logPaymentButton = app.buttons["recommendation.logPaymentButton"]
        XCTAssertTrue(reveal(logPaymentButton, in: app))
        revealAndTap(logPaymentButton, in: app)

        let disabledPredicate = NSPredicate(format: "isEnabled == false")
        let disabledExpectation = XCTNSPredicateExpectation(predicate: disabledPredicate, object: logPaymentButton)
        XCTAssertEqual(XCTWaiter().wait(for: [disabledExpectation], timeout: 5), .completed)

        let loggedPaymentMessage = app.staticTexts["recommendation.loggedPaymentMessage"]
        _ = loggedPaymentMessage.waitForExistence(timeout: 2)
    }

    private func createLoggedPayment(in app: XCUIApplication) {
        let showRecommendationButton = app.buttons["home.showRecommendationButton"]
        XCTAssertTrue(showRecommendationButton.waitForExistence(timeout: 5))
        revealAndTap(showRecommendationButton, in: app)
        assertRecommendationAndLogPayment(in: app)
        app.buttons["Закрыть"].tap()
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

        let scrollContainer = app.tables.firstMatch.exists
            ? app.tables.firstMatch
            : (app.collectionViews.firstMatch.exists
                ? app.collectionViews.firstMatch
                : app.scrollViews.firstMatch)

        for _ in 0..<5 {
            if scrollContainer.exists {
                scrollContainer.swipeUp()
            } else {
                app.swipeUp()
            }

            if element.waitForExistence(timeout: 1), element.isHittable {
                return true
            }
        }

        return element.exists && element.isHittable
    }

    private func payloadField(in app: XCUIApplication) -> XCUIElement {
        let textField = app.textFields["scanner.payloadField"]
        if textField.exists {
            return textField
        }

        return app.textViews["scanner.payloadField"]
    }
}
