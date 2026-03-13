import SwiftUI

struct HistoryView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        List {
            if appModel.loggedPayments.isEmpty {
                EmptyStateView(
                    title: "История пока пуста",
                    message: "После первой подтвержденной оплаты здесь появятся записи.",
                    systemImage: "clock.badge.questionmark"
                )
                .accessibilityIdentifier("history.emptyState")
            } else {
                ForEach(appModel.loggedPayments) { payment in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(payment.merchantName ?? payment.category.displayName)
                            .font(.headline)
                        Text("\(CurrencyFormatter.rubles(payment.amount)) · \(payment.channel.displayName)")
                            .foregroundStyle(.secondary)
                        Text("Источник: \(payment.source.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("history.paymentSource")
                        Text("Оплачено: \(appModel.paymentMethodName(for: payment.actualPaymentMethodId))")
                        Text("Ожидание: \(CurrencyFormatter.rubles(payment.expectedReward ?? 0))")
                            .foregroundStyle(.secondary)
                        if let recommendedPaymentMethodId = payment.recommendedPaymentMethodId {
                            Text("Рекомендовано: \(appModel.paymentMethodName(for: recommendedPaymentMethodId))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(payment.wasRecommendationUsed ? "Рекомендация была использована" : "Оплачено другим способом")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityIdentifier("history.paymentRow.\(payment.id.uuidString)")
                }
            }
        }
        .navigationTitle("История")
    }
}
