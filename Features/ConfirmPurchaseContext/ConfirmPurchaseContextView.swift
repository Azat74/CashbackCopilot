import SwiftUI

struct ConfirmPurchaseContextView: View {
    let parsedPayload: ParsedQRPayload
    let rawPayload: String

    @State private var amountText: String
    @State private var merchantName: String
    @State private var selectedCategory: CashbackCategory
    @State private var selectedChannel: PaymentChannel
    @State private var recommendationContext: PurchaseContext?

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
            }

            Section("Подтвердите перед расчетом") {
                TextField("Сумма", text: $amountText)
                    .keyboardType(.decimalPad)
                    .accessibilityIdentifier("confirm.amountField")

                TextField("Merchant", text: $merchantName)
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

                if let validationMessage {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("confirm.validationMessage")
                } else if parsedPayload.confidence < 0.75 {
                    Text("Категория определена предположительно. Проверьте её перед расчетом.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .accessibilityIdentifier("confirm.warningMessage")
                }
            }

            Section {
                Button("Показать рекомендацию") {
                    if let context = makeContext() {
                        recommendationContext = context
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(validationMessage != nil)
                .accessibilityIdentifier("confirm.showRecommendationButton")
            }
        }
        .navigationTitle("Подтвердить контекст")
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
