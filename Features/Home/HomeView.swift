import SwiftUI

struct HomeView: View {
    private enum UITestDefaults {
        static let isEnabled = ProcessInfo.processInfo.arguments.contains("UITEST_SMOKE")
        static let amount = "1500"
        static let merchant = "АЗС"
    }

    private enum Field: Hashable {
        case amount
        case merchant
    }

    @Environment(AppModel.self) private var appModel

    @State private var amountText = UITestDefaults.isEnabled ? UITestDefaults.amount : ""
    @State private var merchantName = UITestDefaults.isEnabled ? UITestDefaults.merchant : ""
    @State private var selectedCategory: CashbackCategory = .fuel
    @State private var selectedChannel: PaymentChannel = .card
    @State private var recommendationContext: PurchaseContext?
    @State private var isScannerPresented = false
    @FocusState private var focusedField: Field?

    var body: some View {
        Form {
            Section("Перед оплатой") {
                TextField("Сумма", text: $amountText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
                    .accessibilityIdentifier("home.amountField")

                TextField("Merchant / подсказка", text: $merchantName)
                    .focused($focusedField, equals: .merchant)
                    .accessibilityIdentifier("home.merchantField")

                Picker("Категория", selection: $selectedCategory) {
                    ForEach(CashbackCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .accessibilityIdentifier("home.categoryPicker")

                Picker("Канал оплаты", selection: $selectedChannel) {
                    ForEach(PaymentChannel.allCases, id: \.self) { channel in
                        Text(channel.displayName).tag(channel)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("home.channelPicker")

                if let validationMessage {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("home.validationMessage")
                }
            }

            Section("Быстрые категории") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(CashbackCategory.allCases, id: \.self) { category in
                            Button(category.displayName) {
                                selectedCategory = category
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            if appModel.rules.isEmpty || appModel.paymentMethods.isEmpty {
                Section("Что нужно заполнить") {
                    if appModel.paymentMethods.isEmpty {
                        Text("Добавьте хотя бы один способ оплаты в кошелек.")
                            .accessibilityIdentifier("home.missingPaymentMethodsMessage")
                    }

                    if appModel.rules.isEmpty {
                        Text("Добавьте хотя бы одно правило кешбека, иначе рекомендация будет пустой.")
                            .accessibilityIdentifier("home.missingRulesMessage")
                    }
                }
            }
        }
        .navigationTitle("Главная")
        .scrollDismissesKeyboard(.interactively)
        .sheet(item: $recommendationContext) { context in
            NavigationStack {
                RecommendationView(context: context)
            }
        }
        .sheet(isPresented: $isScannerPresented) {
            NavigationStack {
                ScannerView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button("Показать лучшую оплату") {
                    if let context = makeManualContext() {
                        focusedField = nil
                        DispatchQueue.main.async {
                            recommendationContext = context
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canRequestRecommendation)
                .accessibilityIdentifier("home.showRecommendationButton")

                Button("Открыть сканер QR") {
                    focusedField = nil
                    DispatchQueue.main.async {
                        isScannerPresented = true
                    }
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("home.openScannerButton")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.ultraThinMaterial)
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

        if appModel.paymentMethods.isEmpty {
            return "Сначала добавьте способ оплаты в кошелек."
        }

        if appModel.rules.isEmpty {
            return "Сначала добавьте правило кешбека."
        }

        return nil
    }

    private var canRequestRecommendation: Bool {
        validationMessage == nil
    }

    private func makeManualContext() -> PurchaseContext? {
        guard let normalizedAmount, normalizedAmount > 0 else {
            return nil
        }

        let trimmedMerchantName = merchantName.trimmingCharacters(in: .whitespacesAndNewlines)

        return PurchaseContext(
            source: .manual,
            amount: normalizedAmount,
            merchantName: trimmedMerchantName.isEmpty ? nil : trimmedMerchantName,
            category: selectedCategory,
            channel: selectedChannel,
            confidence: 1.0
        )
    }
}
