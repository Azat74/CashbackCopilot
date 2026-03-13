import Foundation

struct ParsedQRPayload: Equatable {
    var amount: Double?
    var merchantName: String?
    var probableCategory: CashbackCategory
    var channel: PaymentChannel
    var confidence: Double
    var heuristics: [String]
    var warnings: [String]

    var confidenceBand: ParsedQRConfidenceBand {
        switch confidence {
        case 0.8...:
            .high
        case 0.55..<0.8:
            .medium
        default:
            .low
        }
    }
}

enum ParsedQRConfidenceBand: String, Equatable {
    case high
    case medium
    case low

    var displayName: String {
        switch self {
        case .high:
            "Высокая"
        case .medium:
            "Средняя"
        case .low:
            "Низкая"
        }
    }
}

struct QRParsingService {
    func parse(_ payload: String) -> ParsedQRPayload {
        let lowered = payload.lowercased()
        let amount = parseAmount(from: lowered)
        let merchantName = parseMerchant(from: payload)
        let hasSBPHint = lowered.contains("sbp")
        let channel: PaymentChannel = hasSBPHint ? .sbp : .qr
        let probableCategory = inferCategory(from: merchantName, payload: lowered)
        let heuristics = buildHeuristics(
            hasSBPHint: hasSBPHint,
            amount: amount,
            merchantName: merchantName,
            probableCategory: probableCategory
        )
        let warnings = buildWarnings(
            hasSBPHint: hasSBPHint,
            amount: amount,
            merchantName: merchantName,
            probableCategory: probableCategory
        )
        let confidence = baseConfidence(
            hasSBPHint: hasSBPHint,
            amount: amount,
            merchantName: merchantName,
            probableCategory: probableCategory
        )

        return ParsedQRPayload(
            amount: amount,
            merchantName: merchantName,
            probableCategory: probableCategory,
            channel: channel,
            confidence: confidence,
            heuristics: heuristics,
            warnings: warnings
        )
    }

    private func parseAmount(from payload: String) -> Double? {
        let patterns = ["sum=", "amount=", "s="]

        for pattern in patterns {
            guard let range = payload.range(of: pattern) else {
                continue
            }

            let suffix = payload[range.upperBound...]
            let digits = suffix.prefix { $0.isNumber || $0 == "." || $0 == "," }
            let normalized = digits.replacingOccurrences(of: ",", with: ".")
            if let value = Double(normalized), value > 0 {
                return value
            }
        }

        return nil
    }

    private func parseMerchant(from payload: String) -> String? {
        let separators = ["merchant=", "shop=", "name="]

        for separator in separators {
            guard let range = payload.range(of: separator, options: .caseInsensitive) else {
                continue
            }

            let suffix = payload[range.upperBound...]
            let raw = suffix.prefix { $0 != "&" && $0 != ";" && $0 != "\n" }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

            if !trimmed.isEmpty {
                return String(trimmed)
            }
        }

        return nil
    }

    private func inferCategory(from merchantName: String?, payload: String) -> CashbackCategory {
        let haystack = "\(merchantName?.lowercased() ?? "") \(payload)"

        if haystack.contains("азс") || haystack.contains("fuel") || haystack.contains("gas") {
            return .fuel
        }

        if haystack.contains("апт") || haystack.contains("pharm") {
            return .pharmacy
        }

        if haystack.contains("taxi") || haystack.contains("такси") {
            return .taxi
        }

        if haystack.contains("каф") || haystack.contains("coffee") {
            return .cafes
        }

        if haystack.contains("рест") || haystack.contains("restaurant") {
            return .restaurants
        }

        if haystack.contains("market") || haystack.contains("суперм") || haystack.contains("продукт") {
            return .groceries
        }

        return .other
    }

    private func buildHeuristics(
        hasSBPHint: Bool,
        amount: Double?,
        merchantName: String?,
        probableCategory: CashbackCategory
    ) -> [String] {
        var heuristics: [String] = []

        if hasSBPHint {
            heuristics.append("Payload содержит явный признак СБП.")
        }

        if amount != nil {
            heuristics.append("Сумма покупки извлечена из QR.")
        }

        if merchantName != nil {
            heuristics.append("Название merchant извлечено из payload.")
        }

        if probableCategory != .other {
            heuristics.append("Категория предположена по merchant и тексту payload.")
        } else {
            heuristics.append("Надежных признаков категории в payload не найдено.")
        }

        return heuristics
    }

    private func buildWarnings(
        hasSBPHint: Bool,
        amount: Double?,
        merchantName: String?,
        probableCategory: CashbackCategory
    ) -> [String] {
        var warnings: [String] = []

        if amount == nil {
            warnings.append("Сумма не найдена в QR. Проверьте её вручную перед расчетом.")
        }

        if merchantName == nil {
            warnings.append("Merchant не распознан. Банк может классифицировать покупку иначе.")
        }

        if probableCategory == .other {
            warnings.append("Категория не распознана. Лучше выбрать её вручную.")
        }

        if !hasSBPHint {
            warnings.append("Канал определен как обычный QR без явного признака СБП.")
        }

        return warnings
    }

    private func baseConfidence(
        hasSBPHint: Bool,
        amount: Double?,
        merchantName: String?,
        probableCategory: CashbackCategory
    ) -> Double {
        var confidence = 0.2

        if hasSBPHint {
            confidence += 0.2
        }

        if amount != nil {
            confidence += 0.15
        }

        if merchantName != nil {
            confidence += 0.15
        }

        if probableCategory != .other {
            confidence += 0.2
        }

        if merchantName != nil, amount != nil, probableCategory != .other {
            confidence += 0.1
        }

        return min(confidence, 0.9)
    }
}
