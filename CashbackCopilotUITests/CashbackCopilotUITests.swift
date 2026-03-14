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
        dismissKeyboardIfNeeded(in: app)
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
        dismissKeyboardIfNeeded(in: app)
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

        let amountField = revealConfirmActualCashbackAmountField(in: app)
        XCTAssertTrue(reveal(amountField, in: app))
        amountField.tap()
        amountField.typeText("75")

        let saveButton = app.buttons["confirmActualCashback.saveButton"]
        XCTAssertTrue(saveButton.exists)
        saveButton.tap()

        let reviewButton = app.buttons["Проверить запись"].firstMatch
        XCTAssertTrue(reviewButton.waitForExistence(timeout: 5))

        let statusLabel = app.staticTexts["history.cashbackStatus"].firstMatch
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(statusLabel.label.contains("Совпало"))
    }

    func testHistoryMismatchCanBeReviewedAndCorrected() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SMOKE")
        app.launch()

        startOnboarding(in: app)
        createLoggedPayment(in: app)

        app.tabBars.buttons["История"].tap()

        let reviewButton = app.buttons["history.reviewPaymentButton"].firstMatch
        XCTAssertTrue(reviewButton.waitForExistence(timeout: 5))
        revealAndTap(reviewButton, in: app)

        let amountField = revealConfirmActualCashbackAmountField(in: app)
        XCTAssertTrue(reveal(amountField, in: app))
        amountField.tap()
        amountField.typeText("45")

        let saveButton = app.buttons["confirmActualCashback.saveButton"]
        XCTAssertTrue(saveButton.exists)
        saveButton.tap()

        XCTAssertTrue(app.staticTexts["history.mismatchHint"].waitForExistence(timeout: 5))

        revealAndTap(reviewButton, in: app)

        let paymentMethodPicker = confirmActualCashbackPaymentMethodPicker(in: app)
        XCTAssertTrue(paymentMethodPicker.waitForExistence(timeout: 5))
        paymentMethodPicker.tap()

        let sbpOption = confirmActualCashbackPaymentMethodOption(named: "Т-Банк · СБП", in: app)
        XCTAssertTrue(reveal(sbpOption, in: app))
        sbpOption.tap()

        let correctionSaveButton = app.buttons["confirmActualCashback.saveButton"]
        XCTAssertTrue(correctionSaveButton.waitForExistence(timeout: 5))
        correctionSaveButton.tap()

        let statusLabel = app.staticTexts["history.cashbackStatus"].firstMatch
        XCTAssertTrue(statusLabel.waitForExistence(timeout: 5))
        XCTAssertTrue(statusLabel.label.contains("Совпало"))
    }

    func testSettingsCanWipeLocalData() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SMOKE")
        app.launch()

        startOnboarding(in: app)

        openSettingsTab(in: app)

        let wipeButton = revealSettingsWipeLocalDataButton(in: app)
        XCTAssertTrue(reveal(wipeButton, in: app))
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

        let historyEmptyState = historyEmptyStateElement(in: app)
        XCTAssertTrue(historyEmptyState.waitForExistence(timeout: 5))
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

        let logPaymentButton = recommendationLogPaymentButton(in: app)
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
        dismissKeyboardIfNeeded(in: app)
        revealAndTap(showRecommendationButton, in: app)
        assertRecommendationAndLogPayment(in: app)
        app.buttons["Закрыть"].tap()
    }

    private func openSettingsTab(in app: XCUIApplication) {
        let settingsTab = app.tabBars.buttons["Настройки"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))

        let settingsScreen = app.otherElements["settings.screen"]
        let settingsNavigationBar = app.navigationBars["Настройки"]
        for _ in 0..<3 {
            settingsTab.tap()
            if settingsScreen.waitForExistence(timeout: 2) || settingsNavigationBar.waitForExistence(timeout: 2) {
                return
            }
        }

        XCTFail("Failed to open Settings tab")
    }

    private func revealAndTap(_ element: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(reveal(element, in: app))
        XCTAssertTrue(element.isHittable)
        element.tap()
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        if element.waitForExistence(timeout: 2), element.isHittable {
            return true
        }

        let scrollContainer = app.tables.firstMatch.exists
            ? app.tables.firstMatch
            : (app.collectionViews.firstMatch.exists
                ? app.collectionViews.firstMatch
                : app.scrollViews.firstMatch)

        for _ in 0..<8 {
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

    private func dismissKeyboardIfNeeded(in app: XCUIApplication) {
        guard app.keyboards.count > 0 else {
            return
        }

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
    }

    private func payloadField(in app: XCUIApplication) -> XCUIElement {
        let textField = app.textFields["scanner.payloadField"]
        if textField.exists {
            return textField
        }

        return app.textViews["scanner.payloadField"]
    }

    private func revealConfirmActualCashbackAmountField(in app: XCUIApplication) -> XCUIElement {
        let candidates = [
            app.textFields["confirmActualCashback.amountField"],
            app.textFields["Сколько реально начислили"],
            app.textFields.firstMatch
        ]

        for field in candidates where reveal(field, in: app) {
            return field
        }

        return candidates[1]
    }

    private func confirmActualCashbackPaymentMethodPicker(in app: XCUIApplication) -> XCUIElement {
        let identifiedPicker = app.buttons["confirmActualCashback.paymentMethodPicker"]
        if identifiedPicker.exists {
            return identifiedPicker
        }

        let labeledPicker = app.buttons["Способ оплаты"]
        if labeledPicker.exists {
            return labeledPicker
        }

        return app.buttons.firstMatch
    }

    private func confirmActualCashbackPaymentMethodOption(named name: String, in app: XCUIApplication) -> XCUIElement {
        let button = app.buttons[name]
        if button.exists {
            return button
        }

        let cell = app.cells.containing(.staticText, identifier: name).firstMatch
        if cell.exists {
            return cell
        }

        return app.staticTexts[name]
    }

    private func recommendationLogPaymentButton(in app: XCUIApplication) -> XCUIElement {
        let identifiedButton = app.buttons["recommendation.logPaymentButton"]
        if identifiedButton.exists {
            return identifiedButton
        }

        let primaryTitleButton = app.buttons["Отметить как оплачено"]
        if primaryTitleButton.exists {
            return primaryTitleButton
        }

        let alternateTitleButton = app.buttons["Отметить оплату другим способом"]
        if alternateTitleButton.exists {
            return alternateTitleButton
        }

        return identifiedButton
    }

    private func settingsWipeLocalDataButton(in app: XCUIApplication) -> XCUIElement {
        let identifiedLabel = app.staticTexts["settings.wipeLocalDataButtonLabel"]
        if identifiedLabel.exists {
            return identifiedLabel
        }

        let titledText = app.staticTexts["Удалить все локальные данные"]
        if titledText.exists {
            return titledText
        }

        let titledCell = app.cells.containing(.staticText, identifier: "Удалить все локальные данные").firstMatch
        if titledCell.exists {
            return titledCell
        }

        let titledButton = app.buttons["Удалить все локальные данные"]
        if titledButton.exists {
            return titledButton
        }

        let identifiedButton = app.buttons["settings.wipeLocalDataButton"]
        if identifiedButton.exists {
            return identifiedButton
        }

        return identifiedLabel
    }

    private func revealSettingsWipeLocalDataButton(in app: XCUIApplication) -> XCUIElement {
        let candidates = [
            app.staticTexts["settings.wipeLocalDataButtonLabel"],
            app.staticTexts["Удалить все локальные данные"],
            app.buttons["settings.wipeLocalDataButton"],
            app.buttons["Удалить все локальные данные"],
            app.cells.containing(.staticText, identifier: "Удалить все локальные данные").firstMatch
        ]

        for candidate in candidates where reveal(candidate, in: app) {
            return candidate
        }

        return candidates[0]
    }

    private func historyEmptyStateElement(in app: XCUIApplication) -> XCUIElement {
        let identifiedContainer = app.otherElements["history.emptyState"]
        if identifiedContainer.exists {
            return identifiedContainer
        }

        let identifiedStaticText = app.staticTexts["history.emptyState"]
        if identifiedStaticText.exists {
            return identifiedStaticText
        }

        return app.staticTexts["История пока пуста"]
    }
}
