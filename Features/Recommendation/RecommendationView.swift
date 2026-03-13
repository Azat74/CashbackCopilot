import SwiftUI

struct RecommendationView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let context: PurchaseContext

    @State private var result: RecommendationResult?
    @State private var didLogPayment = false
    @State private var selectedPaymentMethodID: UUID?

    var body: some View {
        List {
            Section("Контекст покупки") {
                LabeledContent("Сумма", value: CurrencyFormatter.rubles(context.amount))
                LabeledContent("Категория", value: context.category.displayName)
                LabeledContent("Канал", value: context.channel.displayName)

                if let merchantName = context.merchantName {
                    LabeledContent("Merchant", value: merchantName)
                }
            }

            if let result {
                if let best = result.bestOption {
                    Section("Лучший вариант") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(appModel.paymentMethodName(for: best.paymentMethodId))
                                .font(.headline)
                                .accessibilityIdentifier("recommendation.bestMethodName")
                            Text("Ожидаемый кешбек: \(CurrencyFormatter.rubles(best.expectedReward))")
                                .font(.title3.bold())
                                .accessibilityIdentifier("recommendation.expectedReward")
                            Text("Эффективная ставка: \(best.expectedPercent.formatted(.number.precision(.fractionLength(0...2))))%")
                            Text("Confidence: \(best.confidence.formatted(.percent.precision(.fractionLength(0))))")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !best.reasons.isEmpty {
                        Section("Почему") {
                            ForEach(best.reasons, id: \.self) { reason in
                                Text(reason)
                            }
                        }
                    }

                    if !best.risks.isEmpty {
                        Section("Риски") {
                            ForEach(best.risks, id: \.self) { risk in
                                Text(risk)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    if !result.alternatives.isEmpty {
                        Section("Альтернативы") {
                            ForEach(result.alternatives) { option in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appModel.paymentMethodName(for: option.paymentMethodId))
                                    Text("Ожидаемый кешбек: \(CurrencyFormatter.rubles(option.expectedReward))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Section("Фактически оплачено") {
                        Picker("Способ оплаты", selection: paymentMethodSelection) {
                            ForEach(appModel.recommendationPaymentMethodIDs(for: result), id: \.self) { paymentMethodID in
                                Text(appModel.paymentMethodName(for: paymentMethodID))
                                    .tag(Optional(paymentMethodID))
                            }
                        }
                        .accessibilityIdentifier("recommendation.actualPaymentMethodPicker")
                    }

                    Section {
                        Button(logPaymentButtonTitle(for: result)) {
                            appModel.recordPayment(for: context, result: result, actualPaymentMethodID: selectedPaymentMethodID)
                            didLogPayment = true
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(didLogPayment)
                        .accessibilityIdentifier("recommendation.logPaymentButton")

                        if didLogPayment {
                            Text("Оплата зафиксирована локально, лимиты обновлены.")
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("recommendation.loggedPaymentMessage")
                        }
                    }
                } else {
                    Section {
                        EmptyStateView(
                            title: "Подходящий способ не найден",
                            message: "Проверь сумму, категорию, канал оплаты или текущие лимиты.",
                            systemImage: "exclamationmark.circle"
                        )
                    }
                }
            } else {
                Section {
                    ProgressView("Считаем рекомендацию…")
                        .accessibilityIdentifier("recommendation.loadingIndicator")
                }
            }
        }
        .navigationTitle("Рекомендация")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Закрыть") {
                    dismiss()
                }
            }
        }
        .task {
            guard result == nil else { return }
            let computedResult = appModel.makeRecommendation(for: context)
            result = computedResult
            selectedPaymentMethodID = computedResult.bestOption?.paymentMethodId
        }
    }

    private var paymentMethodSelection: Binding<UUID?> {
        Binding(
            get: { selectedPaymentMethodID },
            set: { selectedPaymentMethodID = $0 }
        )
    }

    private func logPaymentButtonTitle(for result: RecommendationResult) -> String {
        if selectedPaymentMethodID == result.bestOption?.paymentMethodId {
            return "Отметить как оплачено"
        }

        return "Отметить оплату другим способом"
    }
}
