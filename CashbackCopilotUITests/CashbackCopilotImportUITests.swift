import XCTest

@MainActor
final class CashbackCopilotImportUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testScreenshotImportShellCanLoadDemoScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SMOKE")
        app.launch()

        let startButton = app.buttons["onboarding.startButton"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        let walletTab = app.tabBars.buttons["Кошелек"]
        XCTAssertTrue(walletTab.waitForExistence(timeout: 5))
        walletTab.tap()

        let walletNavigationBar = app.navigationBars["Кошелек"]
        XCTAssertTrue(walletNavigationBar.waitForExistence(timeout: 5))

        let openImportButton = app.buttons["wallet.openImportButton"].firstMatch
        XCTAssertTrue(openImportButton.waitForExistence(timeout: 5))
        XCTAssertTrue(openImportButton.isHittable)
        openImportButton.tap()

        let importNavigationBar = app.navigationBars["Импорт кешбека"]
        XCTAssertTrue(importNavigationBar.waitForExistence(timeout: 5))

        let demoLoadButton = app.buttons["import.loadDemoScreenshotsButton"]
        XCTAssertTrue(demoLoadButton.waitForExistence(timeout: 5))
        XCTAssertTrue(demoLoadButton.isHittable)
        demoLoadButton.tap()

        let selectedCount = app.staticTexts["import.selectedCount"]
        XCTAssertTrue(selectedCount.waitForExistence(timeout: 5))
        XCTAssertTrue(selectedCount.label.contains("2"))

        let ocrReadyState = app.staticTexts["import.ocrReadyState"]
        XCTAssertTrue(ocrReadyState.waitForExistence(timeout: 5))

        let ocrPreviewCard = app.otherElements["import.ocrPreviewCard"].firstMatch
        XCTAssertTrue(ocrPreviewCard.waitForExistence(timeout: 5))
    }
}
