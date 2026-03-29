import Foundation

struct ScreenshotImportOCRBatchResult: Equatable {
    let screenshots: [RecognizedImportScreenshot]
    let failedScreenshotCount: Int
}

struct ScreenshotImportOCRPipeline: Sendable {
    private let ocrService: any OCRService

    init(ocrService: any OCRService = VisionOCRService()) {
        self.ocrService = ocrService
    }

    func recognize(_ screenshots: [ImportScreenshotAsset]) async -> ScreenshotImportOCRBatchResult {
        var recognizedScreenshots: [RecognizedImportScreenshot] = []
        var failedScreenshotCount = 0

        for screenshot in screenshots {
            if let demoRecognizedText = screenshot.demoRecognizedText {
                recognizedScreenshots.append(
                    RecognizedImportScreenshot(
                        id: screenshot.id,
                        title: screenshot.title,
                        previewImageData: screenshot.imageData,
                        placeholderSystemImage: screenshot.placeholderSystemImage,
                        textBlocks: OCRTextBlock.demoBlocks(from: demoRecognizedText)
                    )
                )
                continue
            }

            guard let imageData = screenshot.imageData else {
                failedScreenshotCount += 1
                continue
            }

            do {
                let textBlocks = try await ocrService.recognizeText(in: imageData)
                recognizedScreenshots.append(
                    RecognizedImportScreenshot(
                        id: screenshot.id,
                        title: screenshot.title,
                        previewImageData: imageData,
                        placeholderSystemImage: screenshot.placeholderSystemImage,
                        textBlocks: textBlocks
                    )
                )
            } catch {
                failedScreenshotCount += 1
            }
        }

        return ScreenshotImportOCRBatchResult(
            screenshots: recognizedScreenshots,
            failedScreenshotCount: failedScreenshotCount
        )
    }
}
