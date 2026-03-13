import Foundation

struct ParsedQRPayload: Equatable {
    var amount: Double?
    var merchantName: String?
    var channel: PaymentChannel
    var confidence: Double
}

struct QRParsingService {
    func parse(_ payload: String) -> ParsedQRPayload {
        let lowered = payload.lowercased()
        let amount = parseAmount(from: lowered)
        let merchantName = parseMerchant(from: payload)
        let channel: PaymentChannel = lowered.contains("sbp") ? .sbp : .qr
        let confidence = merchantName == nil ? 0.45 : 0.6

        return ParsedQRPayload(
            amount: amount,
            merchantName: merchantName,
            channel: channel,
            confidence: confidence
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
}

