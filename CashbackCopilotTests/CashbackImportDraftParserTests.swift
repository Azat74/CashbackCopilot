import XCTest
@testable import CashbackCopilot

final class CashbackImportDraftParserTests: XCTestCase {
    func testMakeDraftParsesCategoryPercentLinesIntoRules() {
        let parser = CashbackImportDraftParser()
        let bank = Bank(name: "Т-Банк")

        let screenshots = [
            RecognizedImportScreenshot(
                screenshotId: UUID(),
                title: "Категории месяца",
                recognizedText: "АЗС 5%\nКафе и рестораны 7%\nМаркетплейсы 3%",
                textBlocks: []
            )
        ]

        let draft = parser.makeDraft(from: screenshots, bank: bank)

        XCTAssertNotNil(draft)
        XCTAssertEqual(draft?.rules.count, 3)
        XCTAssertEqual(draft?.rules.map(\.category), [.fuel, .cafes, .marketplaces])
        XCTAssertEqual(draft?.rules.map(\.percent), [5, 7, 3])
    }

    func testMakeDraftIgnoresConditionOnlyLines() {
        let parser = CashbackImportDraftParser()
        let bank = Bank(name: "Т-Банк")

        let screenshots = [
            RecognizedImportScreenshot(
                screenshotId: UUID(),
                title: "Условия категории",
                recognizedText: "Лимит 1000 ₽ в месяц\nНе действует при оплате по QR",
                textBlocks: []
            )
        ]

        let draft = parser.makeDraft(from: screenshots, bank: bank)

        XCTAssertNil(draft)
    }
}
