import SwiftUI

struct ConfirmPurchaseContextView: View {
    private enum Field: Hashable {
        case amount
        case merchant
    }

    let parsedPayload: ParsedQRPayload
    let rawPayload: String

    @State private var amountText: String
    @State private var merchantName: String
    @State private var selectedCategory: CashbackCategory
    @State private var selectedChannel: PaymentChannel
    @State private var recommendationContext: PurchaseContext?
    @FocusState private var focusedField: Field?

    init(parsedPayload: ParsedQRPayload, rawPayload: String) {
        self.parsedPayload = parsedPayload
        self.rawPayload = rawPayload
        _amountText = State(initialValue: parsedPayload.amount.map(Self.initialAmountText) ?? "")
        _merchantName = State(initialValue: parsedPayload.merchantName ?? "")
        _selectedCategory = State(initialValue: parsedPayload.probableCategory)
        _selectedChannel = State(initialValue: parsedPayload.channel)
    }

    var body: some View {
        Form {
            Section("Что распознали") {
                LabeledContent("Канал", value: parsedPayload.channel.displayName)
                    .accessibilityIdentifier("confirm.detectedChannel")
                LabeledContent("Категория", value: parsedPayload.probableCategory.displayName)
                    .accessibilityIdentifier("confirm.detectedCategory")
                LabeledContent("Confidence", value: parsedPayload.confidence.formatted(.percent.precision(.fractionLength(0))))
                    .accessibilityIdentifier("confirm.detectedConfidence")
                LabeledContent("Оценка", value: parsedPayload.confidenceBand.displayName)
                    .accessibilityIdentifier("confirm.detectedConfidenceBand")
            }

            if !parsedPayload.heuristics.isEmpty {
                Section("Почему так решили") {
                    ForEach(Array(parsedPayload.heuristics.enumerated()), id: \.offset) { index, heuristic in
                        Label(heuristic, systemImage: "sparkle.magnifyingglass")
                            .accessibilityIdentifier("confirm.heuristic.\(index)")
                    }
                }
            }

            Section("Подтвердите перед расчетом") {
                TextField("Сумма", text: $amountText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
                    .accessibilityIdentifier("confirm.amountField")

                TextField("Merchant", text: $merchantName)
                    .focused($focusedField, equals: .merchant)
                    .accessibilityIdentifier("confirm.merchantField")

                Picker("Категория", selection: $selectedCategory) {
                    ForEach(CashbackCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .accessibilityIdentifier("confirm.categoryPicker")

                Picker("Канал оплаты", selection: $selectedChannel) {
                    ForEach(PaymentChannel.allCases, id: \.self) { channel in
                        Text(channel.displayName).tag(channel)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("confirm.channelPicker")
            }

            if let validationMessage {
                Section("Проверьте ввод") {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("confirm.validationMessage")
                }
            }

            if !warnings.isEmpty {
                Section("Что проверить перед оплатой") {
                    ForEach(Array(warnings.enumerated()), id: \.offset) { index, warning in
                        Label(warning, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .accessibilityIdentifier("confirm.warning.\(index)")
                    }
                }
            }

            Section {
                Button("Показать рекомендацию") {
                    if let context = makeContext() {
                        focusedField = nil
                        DispatchQueue.main.async {
                            recommendationContext = context
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(validationMessage != nil)
                .accessibilityIdentifier("confirm.showRecommendationButton")
            }
        }
        .navigationTitle("Подтвердить контекст")
        .scrollDismissesKeyboard(.interactively)
        .navigationDestination(item: $recommendationContext) { context in
            RecommendationView(context: context)
        }
    }

    private var normalizedAmount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var validationMessage: String? {
        guard !amountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Введите сумму покупки."
        }

        guard let normalizedAmount else {
            return "Сумма должна быть числом."
        }

        guard normalizedAmount > 0 else {
            return "Сумма должна быть больше нуля."
        }

        return nil
    }

    private var warnings: [String] {
        var result = parsedPayload.warnings

        if parsedPayload.confidenceBand != .high {
            result.append("Confidence ниже высокой. Лучше перепроверить категорию и канал вручную.")
        }

        if selectedCategory != parsedPayload.probableCategory {
            result.append("Категория изменена вручную относительно распознанной версии.")
        }

        if selectedChannel != parsedPayload.channel {
            result.append("Канал оплаты изменен вручную относительно распознанной версии.")
        }

        if merchantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.append("Merchant не заполнен. История и последующая сверка будут менее точными.")
        }

        return Array(NSOrderedSet(array: result)) as? [String] ?? result
    }

    private func makeContext() -> PurchaseContext? {
        guard let normalizedAmount, normalizedAmount > 0 else {
            return nil
        }

        let trimmedMerchant = merchantName.trimmingCharacters(in: .whitespacesAndNewlines)

        return PurchaseContext(
            source: .qr,
            amount: normalizedAmount,
            merchantName: trimmedMerchant.isEmpty ? nil : trimmedMerchant,
            category: selectedCategory,
            channel: selectedChannel,
            qrPayload: rawPayload,
            confidence: parsedPayload.confidence
        )
    }

    private static func initialAmountText(_ amount: Double) -> String {
        if amount.rounded() == amount {
            return String(Int(amount))
        }

        return amount.formatted(.number.precision(.fractionLength(0...2)))
    }
}
