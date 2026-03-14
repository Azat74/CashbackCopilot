import SwiftUI

struct RuleEditorView: View {
    private enum Field: Hashable {
        case title
        case rewardValue
        case minAmount
        case monthlyRewardCap
        case monthlySpendCap
    }

    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let preselectedPaymentMethodID: UUID?

    @State private var selectedPaymentMethodID: UUID?
    @State private var title = ""
    @State private var category: CashbackCategory = .groceries
    @State private var rewardMode: RewardMode = .percent
    @State private var rewardValue = ""
    @State private var minAmount = ""
    @State private var monthlyRewardCap = ""
    @State private var monthlySpendCap = ""
    @State private var qrAllowed = false
    @State private var sbpAllowed = false
    @FocusState private var focusedField: Field?

    init(preselectedPaymentMethodID: UUID? = nil) {
        self.preselectedPaymentMethodID = preselectedPaymentMethodID
        _selectedPaymentMethodID = State(initialValue: preselectedPaymentMethodID)
    }

    var body: some View {
        Form {
            if appModel.paymentMethods.isEmpty {
                EmptyStateView(
                    title: "Нет способов оплаты",
                    message: "Сначала добавьте банк и способ оплаты в кошельке.",
                    systemImage: "creditcard.trianglebadge.exclamationmark"
                )
            } else {
                Section("Способ оплаты") {
                    Picker("Привязка", selection: $selectedPaymentMethodID) {
                        Text("Выберите способ").tag(Optional<UUID>.none)

                        ForEach(appModel.paymentMethods, id: \.id) { method in
                            let bankName = appModel.bankName(for: method.id)
                            Text("\(bankName) · \(method.displayName)").tag(Optional(method.id))
                        }
                    }
                }

                Section("Основные условия") {
                    TextField("Название правила", text: $title)
                        .focused($focusedField, equals: .title)

                    Picker("Категория", selection: $category) {
                        ForEach(CashbackCategory.allCases, id: \.self) { item in
                            Text(item.displayName).tag(item)
                        }
                    }

                    Picker("Тип выгоды", selection: $rewardMode) {
                        ForEach(RewardMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField(rewardMode.placeholder, text: $rewardValue)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .rewardValue)
                }

                Section("Лимиты") {
                    TextField("Минимальная сумма", text: $minAmount)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .minAmount)

                    TextField("Лимит по кешбеку в месяц", text: $monthlyRewardCap)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .monthlyRewardCap)

                    TextField("Лимит по тратам в месяц", text: $monthlySpendCap)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .monthlySpendCap)
                }

                Section("Каналы оплаты") {
                    Toggle("Разрешить QR", isOn: $qrAllowed)
                    Toggle("Разрешить СБП", isOn: $sbpAllowed)
                }

                if let summary = selectedMethodSummary {
                    Section("Куда сохранится правило") {
                        Text(summary)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Правила")
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
                    focusedField = nil
                    saveRule()
                }
                .disabled(!canSave)
            }
        }
    }

    private var canSave: Bool {
        selectedPaymentMethodID != nil &&
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        parsedRewardValue != nil
    }

    private var parsedRewardValue: Double? {
        parseDecimal(rewardValue)
    }

    private var selectedMethodSummary: String? {
        guard let selectedPaymentMethodID,
              let method = appModel.paymentMethods.first(where: { $0.id == selectedPaymentMethodID }) else {
            return nil
        }

        return "\(appModel.bankName(for: method.id)) · \(method.displayName)"
    }

    private func saveRule() {
        guard let paymentMethodID = selectedPaymentMethodID,
              let rewardValue = parsedRewardValue else {
            return
        }

        let rule = CashbackRule(
            paymentMethodId: paymentMethodID,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            percent: rewardMode == .percent ? rewardValue : nil,
            fixedReward: rewardMode == .fixed ? rewardValue : nil,
            minAmount: parseDecimal(minAmount),
            monthlyRewardCap: parseDecimal(monthlyRewardCap),
            monthlySpendCap: parseDecimal(monthlySpendCap),
            qrAllowed: qrAllowed,
            sbpAllowed: sbpAllowed
        )

        appModel.addRule(rule)
        dismiss()
    }

    private func parseDecimal(_ value: String) -> Double? {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard !normalized.isEmpty else {
            return nil
        }

        return Double(normalized)
    }
}

private enum RewardMode: CaseIterable {
    case percent
    case fixed

    var displayName: String {
        switch self {
        case .percent:
            "%"
        case .fixed:
            "₽"
        }
    }

    var placeholder: String {
        switch self {
        case .percent:
            "Процент кешбека"
        case .fixed:
            "Фиксированная выплата"
        }
    }
}

#Preview {
    NavigationStack {
        RuleEditorView()
    }
    .environment(PreviewContainer.appModel)
}
