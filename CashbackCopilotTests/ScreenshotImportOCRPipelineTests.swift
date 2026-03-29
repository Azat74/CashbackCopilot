import XCTest
@testable import CashbackCopilot

final class ScreenshotImportOCRPipelineTests: XCTestCase {
    func testRecognizeUsesDemoRecognizedTextWithoutCallingOCRService() async {
        let ocrService = StubOCRService(result: [.init(text: "unused", boundingBox: .zero)])
        let pipeline = ScreenshotImportOCRPipeline(ocrService: ocrService)

        let result = await pipeline.recognize([
            ImportScreenshotAsset(
                title: "Demo screenshot",
                placeholderSystemImage: "photo",
                demoRecognizedText: "АЗС 5%\nЛимит 1000 ₽"
            )
        ])

        XCTAssertEqual(result.failedScreenshotCount, 0)
        XCTAssertEqual(result.screenshots.count, 1)
        XCTAssertEqual(result.screenshots[0].recognizedText, "АЗС 5%\nЛимит 1000 ₽")
        XCTAssertEqual(ocrService.callCount, 0)
    }

    func testRecognizeUsesOCRServiceForImageBackedScreenshot() async {
        let expectedBlocks = [
            OCRTextBlock(text: "Кафе 7%", boundingBox: .zero),
            OCRTextBlock(text: "Не действует по QR", boundingBox: CGRect(x: 0, y: 0.2, width: 1, height: 0.1))
        ]
        let ocrService = StubOCRService(result: expectedBlocks)
        let pipeline = ScreenshotImportOCRPipeline(ocrService: ocrService)

        let result = await pipeline.recognize([
            ImportScreenshotAsset(
                title: "Real screenshot",
                imageData: Data([0x01, 0x02, 0x03])
            )
        ])

        XCTAssertEqual(result.failedScreenshotCount, 0)
        XCTAssertEqual(result.screenshots.count, 1)
        XCTAssertEqual(result.screenshots[0].textBlocks, expectedBlocks)
        XCTAssertEqual(ocrService.callCount, 1)
    }

    func testRecognizeTracksFailedScreenshotsSeparatelyFromSuccessfulOnes() async {
        let ocrService = StubOCRService(result: [.init(text: "АЗС 5%", boundingBox: .zero)])
        ocrService.failOnCall = 2

        let pipeline = ScreenshotImportOCRPipeline(ocrService: ocrService)
        let result = await pipeline.recognize([
            ImportScreenshotAsset(title: "One", imageData: Data([0x01])),
            ImportScreenshotAsset(title: "Two", imageData: Data([0x02])),
            ImportScreenshotAsset(title: "Three", demoRecognizedText: "Лимит 500 ₽")
        ])

        XCTAssertEqual(result.failedScreenshotCount, 1)
        XCTAssertEqual(result.screenshots.count, 2)
        XCTAssertEqual(result.screenshots.map(\.title), ["One", "Three"])
        XCTAssertEqual(ocrService.callCount, 2)
    }
}

private final class StubOCRService: OCRService, @unchecked Sendable {
    let result: [OCRTextBlock]
    var callCount = 0
    var failOnCall: Int?

    init(result: [OCRTextBlock]) {
        self.result = result
    }

    func recognizeText(in imageData: Data) async throws -> [OCRTextBlock] {
        callCount += 1

        if failOnCall == callCount {
            throw StubError()
        }

        return result
    }
}

private struct StubError: Error {}
