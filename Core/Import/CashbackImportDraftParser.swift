import Foundation

struct CashbackImportDraftParser: Sendable {
    private struct PartialDraft {
        var rules: [ParsedRuleDraft]
        var unassignedConditionLines: [String]
    }

    func makeDraft(
        from screenshots: [RecognizedImportScreenshot],
        bank: Bank
    ) -> ParsedCashbackDraft? {
        var parsedRules: [ParsedRuleDraft] = []
        var unassignedConditionLines: [String] = []

        for screenshot in screenshots {
            let partialDraft = parseDraft(
                from: screenshot.recognizedText,
                screenshotTitle: screenshot.title
            )
            parsedRules.append(contentsOf: partialDraft.rules)
            unassignedConditionLines.append(contentsOf: partialDraft.unassignedConditionLines)
        }

        guard !parsedRules.isEmpty || !unassignedConditionLines.isEmpty else {
            return nil
        }

        return ParsedCashbackDraft(
            bankId: bank.id,
            bankName: bank.name,
            sourceScreenshotsCount: screenshots.count,
            rules: parsedRules,
            unassignedConditionLines: unassignedConditionLines
        )
    }

    private func parseDraft(from rawText: String, screenshotTitle: String) -> PartialDraft {
        let lines = rawText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var rules: [ParsedRuleDraft] = []
        var unassignedConditionLines: [String] = []

        for line in lines {
            if let parsedRule = parseRule(from: line, screenshotTitle: screenshotTitle) {
                rules.append(parsedRule)
                continue
            }

            guard isConditionLine(line.lowercased()) else {
                continue
            }

            if let lastIndex = rules.indices.last {
                rules[lastIndex] = attachCondition(
                    line,
                    to: rules[lastIndex]
                )
            } else {
                unassignedConditionLines.append(line)
            }
        }

        return PartialDraft(
            rules: rules,
            unassignedConditionLines: unassignedConditionLines
        )
    }

    private func parseRule(from line: String, screenshotTitle: String) -> ParsedRuleDraft? {
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
        let confidence = baseConfidence(
            title: resolvedTitle,
            category: category,
            percent: percent,
            fixedReward: fixedReward
        )

        return ParsedRuleDraft(
            title: resolvedTitle,
            category: category,
            percent: percent,
            fixedReward: fixedReward,
            confidence: confidence,
            needsReview: needsReview(category: category, confidence: confidence),
            sourceScreenshotTitle: screenshotTitle,
            sourceLine: line
        )
    }

    private func attachCondition(_ line: String, to rule: ParsedRuleDraft) -> ParsedRuleDraft {
        var updatedRule = rule

        if let existing = updatedRule.specialConditionsText, !existing.isEmpty {
            updatedRule.specialConditionsText = "\(existing)\n\(line)"
        } else {
            updatedRule.specialConditionsText = line
        }

        updatedRule.confidence = max(0.35, updatedRule.confidence - 0.2)
        updatedRule.needsReview = true
        return updatedRule
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

    private func baseConfidence(
        title: String,
        category: CashbackCategory,
        percent: Double?,
        fixedReward: Double?
    ) -> Double {
        var confidence = 0.55

        if percent != nil {
            confidence += 0.2
        }

        if fixedReward != nil {
            confidence += 0.1
        }

        if category != .other {
            confidence += 0.15
        } else {
            confidence -= 0.15
        }

        if !title.isEmpty, title != category.displayName {
            confidence += 0.05
        }

        return min(max(confidence, 0.2), 0.95)
    }

    private func needsReview(category: CashbackCategory, confidence: Double) -> Bool {
        category == .other || confidence < 0.8
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
            "сбп",
            "qr",
            "только",
            "максимум",
            "мин.",
            "минимум"
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
