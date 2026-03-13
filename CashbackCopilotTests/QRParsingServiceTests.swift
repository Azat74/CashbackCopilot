import XCTest
@testable import CashbackCopilot

final class QRParsingServiceTests: XCTestCase {
    private let parser = QRParsingService()

    func testParsesSBPPayloadIntoFuelCategory() {
        let payload = "sbp://pay?merchant=АЗС Тест&sum=1500"

        let parsed = parser.parse(payload)

        XCTAssertEqual(parsed.channel, .sbp)
        XCTAssertEqual(parsed.amount, 1500)
        XCTAssertEqual(parsed.merchantName, "АЗС Тест")
        XCTAssertEqual(parsed.probableCategory, .fuel)
        XCTAssertEqual(parsed.confidenceBand, .high)
        XCTAssertGreaterThanOrEqual(parsed.confidence, 0.8)
        XCTAssertTrue(parsed.warnings.isEmpty)
        XCTAssertTrue(parsed.heuristics.contains("Payload содержит явный признак СБП."))
    }

    func testFallsBackToOtherCategoryWhenNoHintsExist() {
        let payload = "qr://pay?amount=890"

        let parsed = parser.parse(payload)

        XCTAssertEqual(parsed.channel, .qr)
        XCTAssertEqual(parsed.amount, 890)
        XCTAssertNil(parsed.merchantName)
        XCTAssertEqual(parsed.probableCategory, .other)
        XCTAssertEqual(parsed.confidenceBand, .low)
        XCTAssertLessThanOrEqual(parsed.confidence, 0.4)
        XCTAssertTrue(parsed.warnings.contains("Merchant не распознан. Банк может классифицировать покупку иначе."))
        XCTAssertTrue(parsed.warnings.contains("Категория не распознана. Лучше выбрать её вручную."))
        XCTAssertTrue(parsed.warnings.contains("Канал определен как обычный QR без явного признака СБП."))
        XCTAssertTrue(parsed.heuristics.contains("Надежных признаков категории в payload не найдено."))
    }
}
