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
        XCTAssertGreaterThan(parsed.confidence, 0.6)
    }

    func testFallsBackToOtherCategoryWhenNoHintsExist() {
        let payload = "qr://pay?amount=890"

        let parsed = parser.parse(payload)

        XCTAssertEqual(parsed.channel, .qr)
        XCTAssertEqual(parsed.amount, 890)
        XCTAssertNil(parsed.merchantName)
        XCTAssertEqual(parsed.probableCategory, .other)
        XCTAssertLessThanOrEqual(parsed.confidence, 0.45)
    }
}
