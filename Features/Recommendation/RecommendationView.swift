import SwiftUI

struct RecommendationView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let context: PurchaseContext

    @State private var result: RecommendationResult?
    @State private var didLogPayment = false

    var body: some View {
        List {
            if let result {
                if let best = result.bestOption {
                    Section("Лучший вариант") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(appModel.paymentMethodName(for: best.paymentMethodId))
                                .font(.headline)
                            Text("Ожидаемый кешбек: \(CurrencyFormatter.rubles(best.expectedReward))")
                                .font(.title3.bold())
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

                    Section {
                        Button("Отметить как оплачено") {
                            appModel.recordPayment(for: context, result: result)
                            didLogPayment = true
                        }
                        .buttonStyle(.borderedProminent)

                        if didLogPayment {
                            Text("Оплата зафиксирована локально, лимиты обновлены.")
                                .foregroundStyle(.secondary)
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
            result = appModel.makeRecommendation(for: context)
        }
    }
}

