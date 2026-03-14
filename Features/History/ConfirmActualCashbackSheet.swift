import SwiftUI

struct ConfirmActualCashbackSheet: View {
    private enum Field: Hashable {
        case actualReward
    }

    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let payment: LoggedPayment

    @State private var selectedCategory: CashbackCategory
    @State private var selectedPaymentMethodID: UUID?
    @State private var actualRewardText: String
    @FocusState private var focusedField: Field?

    init(payment: LoggedPayment) {
        self.payment = payment
        _selectedCategory = State(initialValue: payment.category)
        _selectedPaymentMethodID = State(initialValue: payment.actualPaymentMethodId)
        _actualRewardText = State(initialValue: Self.initialRewardText(payment.actualReward))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Фактический кешбэк") {
                    TextField("Сколько реально начислили", text: $actualRewardText)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .actualReward)
                        .accessibilityIdentifier("confirmActualCashback.amountField")

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("confirmActualCashback.validationMessage")
                    }
                }

                Section("Коррекция") {
                    Picker("Категория", selection: $selectedCategory) {
                        ForEach(CashbackCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .accessibilityIdentifier("confirmActualCashback.categoryPicker")

                    Picker("Способ оплаты", selection: $selectedPaymentMethodID) {
                        Text("Не выбрано").tag(Optional<UUID>.none)
                        ForEach(sortedPaymentMethods) { method in
                            Text(appModel.paymentMethodName(for: method.id))
                                .tag(Optional(method.id))
                        }
                    }
                    .accessibilityIdentifier("confirmActualCashback.paymentMethodPicker")
                }

                Section("После коррекции") {
                    LabeledContent("Новое ожидание", value: expectedRewardPreviewText)
                        .accessibilityIdentifier("confirmActualCashback.expectedReward")
                    LabeledContent("Статус", value: statusPreview.displayName)
                        .accessibilityIdentifier("confirmActualCashback.statusPreview")

                    if let previewMessage {
                        Text(previewMessage)
                            .font(.caption)
                            .foregroundStyle(statusPreview == .matched ? Color.secondary : Color.orange)
                            .accessibilityIdentifier("confirmActualCashback.previewMessage")
                    }
                }

                Section("Покупка") {
                    LabeledContent("Merchant", value: payment.merchantName ?? payment.category.displayName)
                    LabeledContent("Сумма", value: CurrencyFormatter.rubles(payment.amount))
                    LabeledContent("Ожидание", value: CurrencyFormatter.rubles(payment.expectedReward ?? 0))
                    LabeledContent("Канал", value: payment.channel.displayName)
                    LabeledContent("Источник", value: payment.source.displayName)
                    if let recommendedPaymentMethodId = payment.recommendedPaymentMethodId {
                        LabeledContent("Рекомендовано", value: appModel.paymentMethodName(for: recommendedPaymentMethodId))
                    }
                }
            }
            .navigationTitle(payment.actualReward == nil ? "Подтвердить кешбэк" : "Проверить запись")
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        focusedField = nil
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        guard let normalizedActualReward else {
                            return
                        }

                        focusedField = nil
                        appModel.reviewLoggedPayment(
                            for: payment.id,
                            category: selectedCategory,
                            actualPaymentMethodID: selectedPaymentMethodID,
                            actualReward: normalizedActualReward
                        )
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

    private var sortedPaymentMethods: [PaymentMethod] {
        appModel.paymentMethods.sorted {
            let lhs = appModel.paymentMethodName(for: $0.id)
            let rhs = appModel.paymentMethodName(for: $1.id)
            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }
    }

    private var expectedRewardPreview: Double? {
        appModel.expectedRewardPreview(
            for: payment,
            category: selectedCategory,
            actualPaymentMethodID: selectedPaymentMethodID
        )
    }

    private var expectedRewardPreviewText: String {
        guard let selectedPaymentMethodID else {
            return "Выберите способ оплаты"
        }

        let reward = expectedRewardPreview ?? (appModel.paymentMethodName(for: selectedPaymentMethodID) == "Неизвестно" ? nil : 0)
        return reward.map(CurrencyFormatter.rubles) ?? "Нет данных"
    }

    private var statusPreview: CashbackConfirmationStatus {
        guard validationMessage == nil,
              let normalizedActualReward,
              let expectedRewardPreview else {
            return payment.actualReward == nil ? .pending : payment.confirmationStatus
        }

        return abs(expectedRewardPreview - normalizedActualReward) < 0.01 ? .matched : .mismatched
    }

    private var previewMessage: String? {
        guard selectedPaymentMethodID != nil else {
            return "Укажите фактический способ оплаты, чтобы пересчитать ожидание."
        }

        if expectedRewardPreview == 0 {
            return "Для выбранной категории и способа оплаты активное правило кешбэка не найдено."
        }

        guard validationMessage == nil, normalizedActualReward != nil else {
            return nil
        }

        switch statusPreview {
        case .pending:
            return nil
        case .matched:
            return "Ожидание и факт после коррекции совпадают."
        case .mismatched:
            return "После коррекции ожидание всё ещё отличается от фактического кешбэка."
        }
    }

    private var validationMessage: String? {
        guard selectedPaymentMethodID != nil else {
            return "Выберите фактический способ оплаты."
        }

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
