import CoreGraphics
import Foundation

struct OCRTextBlock: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let boundingBox: CGRect

    init(
        id: UUID = UUID(),
        text: String,
        boundingBox: CGRect
    ) {
        self.id = id
        self.text = text
        self.boundingBox = boundingBox
    }

    static func demoBlocks(from rawText: String) -> [OCRTextBlock] {
        rawText
            .split(whereSeparator: \.isNewline)
            .enumerated()
            .map { index, line in
                OCRTextBlock(
                    text: String(line),
                    boundingBox: CGRect(
                        x: 0.08,
                        y: max(0.05, 0.85 - (Double(index) * 0.12)),
                        width: 0.84,
                        height: 0.08
                    )
                )
            }
    }
}

struct ImportScreenshotAsset: Identifiable, Equatable {
    let id: UUID
    let title: String
    let imageData: Data?
    let placeholderSystemImage: String?
    let demoRecognizedText: String?

    init(
        id: UUID = UUID(),
        title: String,
        imageData: Data? = nil,
        placeholderSystemImage: String? = nil,
        demoRecognizedText: String? = nil
    ) {
        self.id = id
        self.title = title
        self.imageData = imageData
        self.placeholderSystemImage = placeholderSystemImage
        self.demoRecognizedText = demoRecognizedText
    }
}

struct RecognizedImportScreenshot: Identifiable, Equatable {
    let id: UUID
    let title: String
    let previewImageData: Data?
    let placeholderSystemImage: String?
    let textBlocks: [OCRTextBlock]

    var recognizedText: String {
        textBlocks
            .map(\.text)
            .joined(separator: "\n")
    }

    var hasRecognizedText: Bool {
        !recognizedText.isEmpty
    }
}

