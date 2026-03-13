import SwiftUI

struct HomeView: View {
    @State private var amountText = "1500"
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
            }

            Section("Быстрые действия") {
                Button("Показать лучшую оплату") {
                    recommendationContext = makeManualContext()
                }
                .buttonStyle(.borderedProminent)

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
        }
        .navigationTitle("Главная")
        .sheet(item: $recommendationContext) { context in
            RecommendationView(context: context)
        }
        .sheet(isPresented: $isScannerPresented) {
            NavigationStack {
                ScannerView()
            }
        }
    }

    private func makeManualContext() -> PurchaseContext {
        PurchaseContext(
            source: .manual,
            amount: Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0,
            merchantName: merchantName.isEmpty ? nil : merchantName,
            category: selectedCategory,
            channel: selectedChannel,
            confidence: 1.0
        )
    }
}

