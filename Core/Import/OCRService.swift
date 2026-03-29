import Foundation
import UIKit
import Vision

protocol OCRService {
    func recognizeText(in imageData: Data) async throws -> [OCRTextBlock]
}

enum OCRServiceError: LocalizedError {
    case unreadableImage

    var errorDescription: String? {
        switch self {
        case .unreadableImage:
            return "Не удалось прочитать изображение для OCR."
        }
    }
}

struct VisionOCRService: OCRService {
    func recognizeText(in imageData: Data) async throws -> [OCRTextBlock] {
        guard let uiImage = UIImage(data: imageData),
              let cgImage = uiImage.cgImage else {
            throw OCRServiceError.unreadableImage
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["ru-RU", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([request])

        let observations = request.results ?? []

        return observations
            .compactMap { observation in
                guard let candidate = observation.topCandidates(1).first else {
                    return nil
                }

                let trimmedText = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedText.isEmpty else {
                    return nil
                }

                return OCRTextBlock(
                    text: trimmedText,
                    boundingBox: observation.boundingBox
                )
            }
            .sorted(by: Self.readingOrder)
    }

    private static func readingOrder(_ lhs: OCRTextBlock, _ rhs: OCRTextBlock) -> Bool {
        let verticalDistance = abs(lhs.boundingBox.midY - rhs.boundingBox.midY)
        if verticalDistance > 0.03 {
            return lhs.boundingBox.midY > rhs.boundingBox.midY
        }

        return lhs.boundingBox.minX < rhs.boundingBox.minX
    }
}

