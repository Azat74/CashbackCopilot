import Foundation

struct CashbackImportDraftParser: Sendable {
    func makeDraft(
        from screenshots: [RecognizedImportScreenshot],
        bank: Bank
    ) -> ParsedCashbackDraft? {
        let parsedRules = screenshots.flatMap { screenshot in
            parseRules(
                from: screenshot.recognizedText,
                screenshotTitle: screenshot.title
            )
        }

        guard !parsedRules.isEmpty else {
            return nil
        }

        return ParsedCashbackDraft(
            bankId: bank.id,
            bankName: bank.name,
            sourceScreenshotsCount: screenshots.count,
            rules: parsedRules
        )
    }

    private func parseRules(from rawText: String, screenshotTitle: String) -> [ParsedRuleDraft] {
        rawText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .compactMap { parseRule(from: $0, screenshotTitle: screenshotTitle) }
    }

    private func parseRule(from line: String, screenshotTitle: String) -> ParsedRuleDraft? {
        let normalized = line.lowercased()
        guard !isConditionLine(normalized) else {
            return nil
        }

        let percent = extractDecimal(
            in: line,
            pattern: #"(\d+(?:[.,]\d+)?)\s*%"#
        )
        let fixedReward = percent == nil
            ? extractDecimal(in: line, pattern: #"(\d+(?:[.,]\d+)?)\s*(?:₽|руб)"#)
            : nil

        guard percent != nil || fixedReward != nil else {
            return nil
        }

        var title = line
        title = title.replacingOccurrences(
            of: #"\d+(?:[.,]\d+)?\s*%"#,
            with: "",
            options: .regularExpression
        )
        title = title.replacingOccurrences(
            of: #"\d+(?:[.,]\d+)?\s*(?:₽|руб)"#,
            with: "",
            options: .regularExpression
        )
        title = title.replacingOccurrences(of: "—", with: " ")
        title = title.replacingOccurrences(of: "-", with: " ")
        title = title.replacingOccurrences(of: "  ", with: " ")
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)

        let category = matchCategory(for: title)
        let resolvedTitle = title.isEmpty ? category.displayName : title

        return ParsedRuleDraft(
            title: resolvedTitle,
            category: category,
            percent: percent,
            fixedReward: fixedReward,
            needsReview: category == .other,
            sourceScreenshotTitle: screenshotTitle,
            sourceLine: line
        )
    }

    private func extractDecimal(in text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let fullRange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: fullRange),
              let captureRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        let value = text[captureRange].replacingOccurrences(of: ",", with: ".")
        return Double(value)
    }

    private func isConditionLine(_ text: String) -> Bool {
        let conditionMarkers = [
            "лимит",
            "не действует",
            "не суммируется",
            "кроме",
            "услов",
            "по qr",
            "по сбп",
            "только",
            "максимум"
        ]

        return conditionMarkers.contains { text.contains($0) }
    }

    private func matchCategory(for title: String) -> CashbackCategory {
        let normalized = title.lowercased()

        let categoryKeywords: [(CashbackCategory, [String])] = [
            (.fuel, ["азс", "заправ"]),
            (.groceries, ["продукт", "супермар", "перекрест", "пятероч", "магнит"]),
            (.cafes, ["кафе", "кофе", "кофейн"]),
            (.restaurants, ["ресторан", "фастфуд", "доставка еды"]),
            (.taxi, ["такси", "яндекс go", "uber"]),
            (.pharmacy, ["аптек"]),
            (.marketplaces, ["маркетплейс", "wildberries", "wb", "ozon", "яндекс маркет"]),
            (.travel, ["путешеств", "авиа", "отел", "гостиниц"]),
            (.transport, ["транспорт", "метро", "электрич", "автобус"])
        ]

        for (category, keywords) in categoryKeywords where keywords.contains(where: normalized.contains) {
            return category
        }

        return .other
    }
}
