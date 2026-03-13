import SwiftUI

struct ConfirmActualCashbackSheet: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let payment: LoggedPayment

    @State private var actualRewardText: String

    init(payment: LoggedPayment) {
        self.payment = payment
        _actualRewardText = State(initialValue: Self.initialRewardText(payment.actualReward))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Покупка") {
                    LabeledContent("Merchant", value: payment.merchantName ?? payment.category.displayName)
                    LabeledContent("Ожидание", value: CurrencyFormatter.rubles(payment.expectedReward ?? 0))
                }

                Section("Фактический кешбэк") {
                    TextField("Сколько реально начислили", text: $actualRewardText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("confirmActualCashback.amountField")

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("confirmActualCashback.validationMessage")
                    }
                }
            }
            .navigationTitle("Подтвердить кешбэк")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        guard let normalizedActualReward else {
                            return
                        }

                        appModel.confirmActualCashback(for: payment.id, amount: normalizedActualReward)
                        dismiss()
                    }
                    .disabled(validationMessage != nil)
                    .accessibilityIdentifier("confirmActualCashback.saveButton")
                }
            }
        }
    }

    private var normalizedActualReward: Double? {
        Double(actualRewardText.replacingOccurrences(of: ",", with: "."))
    }

    private var validationMessage: String? {
        guard !actualRewardText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Введите фактический кешбэк."
        }

        guard let normalizedActualReward else {
            return "Фактический кешбэк должен быть числом."
        }

        guard normalizedActualReward >= 0 else {
            return "Фактический кешбэк не может быть отрицательным."
        }

        return nil
    }

    private static func initialRewardText(_ reward: Double?) -> String {
        guard let reward else {
            return ""
        }

        if reward.rounded() == reward {
            return String(Int(reward))
        }

        return reward.formatted(.number.precision(.fractionLength(0...2)))
    }
}
