import SwiftUI

struct HistoryView: View {
    @Environment(AppModel.self) private var appModel
    @State private var reviewingPayment: LoggedPayment?

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
                        Text("Категория: \(payment.category.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("history.paymentCategory")
                        Text("Источник: \(payment.source.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("history.paymentSource")
                        Text("Оплачено: \(appModel.paymentMethodName(for: payment.actualPaymentMethodId))")
                        Text("Ожидание: \(CurrencyFormatter.rubles(payment.expectedReward ?? 0))")
                            .foregroundStyle(.secondary)
                        Text("Статус кешбэка: \(payment.confirmationStatus.displayName)")
                            .font(.caption)
                            .foregroundStyle(statusColor(for: payment.confirmationStatus))
                            .accessibilityIdentifier("history.cashbackStatus")
                        if payment.confirmationStatus == .mismatched {
                            Text("Проверьте категорию, способ оплаты или фактический кешбэк.")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .accessibilityIdentifier("history.mismatchHint")
                        }
                        if let actualReward = payment.actualReward {
                            Text("Факт: \(CurrencyFormatter.rubles(actualReward))")
                                .foregroundStyle(.secondary)
                                .accessibilityIdentifier("history.actualReward")
                        }
                        if let recommendedPaymentMethodId = payment.recommendedPaymentMethodId {
                            Text("Рекомендовано: \(appModel.paymentMethodName(for: recommendedPaymentMethodId))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(payment.wasRecommendationUsed ? "Рекомендация была использована" : "Оплачено другим способом")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button(reviewButtonTitle(for: payment)) {
                            reviewingPayment = payment
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("history.reviewPaymentButton")
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("История")
        .sheet(item: $reviewingPayment) { payment in
            ConfirmActualCashbackSheet(payment: payment)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func reviewButtonTitle(for payment: LoggedPayment) -> String {
        switch payment.confirmationStatus {
        case .pending:
            return "Подтвердить фактический кешбэк"
        case .matched:
            return "Проверить запись"
        case .mismatched:
            return "Исправить несоответствие"
        }
    }

    private func statusColor(for status: CashbackConfirmationStatus) -> Color {
        switch status {
        case .pending:
            .orange
        case .matched:
            .green
        case .mismatched:
            .red
        }
    }
}
