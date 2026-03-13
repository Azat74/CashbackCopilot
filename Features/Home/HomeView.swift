import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel

    @State private var amountText = ""
    @State private var merchantName = ""
    @State private var selectedCategory: CashbackCategory = .fuel
    @State private var selectedChannel: PaymentChannel = .card
    @State private var recommendationContext: PurchaseContext?
    @State private var isScannerPresented = false

    var body: some View {
        Form {
            Section("Перед оплатой") {
                TextField("Сумма", text: $amountText)
                    .keyboardType(.decimalPad)

                TextField("Merchant / подсказка", text: $merchantName)

                Picker("Категория", selection: $selectedCategory) {
                    ForEach(CashbackCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }

                Picker("Канал оплаты", selection: $selectedChannel) {
                    ForEach(PaymentChannel.allCases, id: \.self) { channel in
                        Text(channel.displayName).tag(channel)
                    }
                }
                .pickerStyle(.segmented)

                if let validationMessage {
                    Text(validationMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Быстрые действия") {
                Button("Показать лучшую оплату") {
                    if let context = makeManualContext() {
                        recommendationContext = context
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canRequestRecommendation)

                Button("Открыть сканер QR") {
                    isScannerPresented = true
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
                    }

                    if appModel.rules.isEmpty {
                        Text("Добавьте хотя бы одно правило кешбека, иначе рекомендация будет пустой.")
                    }
                }
            }
        }
        .navigationTitle("Главная")
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
