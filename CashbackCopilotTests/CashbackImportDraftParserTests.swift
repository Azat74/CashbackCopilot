import XCTest
@testable import CashbackCopilot

final class CashbackImportDraftParserTests: XCTestCase {
    func testMakeDraftParsesCategoryPercentLinesIntoRules() {
        let parser = CashbackImportDraftParser()
        let bank = Bank(name: "Т-Банк")

        let screenshots = [
            RecognizedImportScreenshot(
                id: UUID(),
                title: "Категории месяца",
                previewImageData: nil,
                placeholderSystemImage: "photo",
                textBlocks: OCRTextBlock.demoBlocks(
                    from: "АЗС 5%\nКафе и рестораны 7%\nМаркетплейсы 3%"
                )
            )
        ]

        let draft = parser.makeDraft(from: screenshots, bank: bank)

        XCTAssertNotNil(draft)
        XCTAssertEqual(draft?.rules.count, 3)
        XCTAssertEqual(draft?.rules.map { $0.category }, [.fuel, .cafes, .marketplaces])
        XCTAssertEqual(draft?.rules.map { $0.percent }, [5, 7, 3])
    }

    func testMakeDraftIgnoresConditionOnlyLines() {
        let parser = CashbackImportDraftParser()
        let bank = Bank(name: "Т-Банк")

        let screenshots = [
            RecognizedImportScreenshot(
                id: UUID(),
                title: "Условия категории",
                previewImageData: nil,
                placeholderSystemImage: "text.bubble",
                textBlocks: OCRTextBlock.demoBlocks(
                    from: "Лимит 1000 ₽ в месяц\nНе действует при оплате по QR"
                )
            )
        ]

        let draft = parser.makeDraft(from: screenshots, bank: bank)

        XCTAssertNil(draft)
    }
}
