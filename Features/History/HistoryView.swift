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
            } else {
                ForEach(appModel.loggedPayments) { payment in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appModel.paymentMethodName(for: payment.actualPaymentMethodId))
                            .font(.headline)
                        Text("Ожидание: \(CurrencyFormatter.rubles(payment.expectedReward ?? 0))")
                            .foregroundStyle(.secondary)
                        Text(payment.wasRecommendationUsed ? "Рекомендация была использована" : "Оплачено другим способом")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("История")
    }
}

