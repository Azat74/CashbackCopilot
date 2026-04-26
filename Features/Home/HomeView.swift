import SwiftUI

struct HomeView: View {
    private struct RecommendationPresentation: Identifiable {
        let id = UUID()
        let context: PurchaseContext
    }

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
    @State private var recommendationPresentation: RecommendationPresentation?
    @State private var isScannerPresented = false
    @FocusState private var focusedField: Field?

    var body: some View {
        let quickSnapshots = appModel.quickRecommendationSnapshots(
            amount: normalizedAmount,
            merchantName: merchantName,
            channel: selectedChannel
        )
        let recentIntents = appModel.recentPurchaseIntents()

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

            if !quickSnapshots.isEmpty {
                Section("Быстрые подсказки") {
                    if usesFallbackSnapshotAmount {
                        Text("Подсказки посчитаны для типовой суммы \(CurrencyFormatter.rubles(snapshotPreviewAmount)).")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("home.quickSnapshotsFallbackAmountMessage")
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(quickSnapshots) { snapshot in
                                Button {
                                    selectedCategory = snapshot.category
                                    focusedField = nil
                                    presentRecommendation(snapshot.context)
                                } label: {
                                    QuickRecommendationSnapshotCard(
                                        snapshot: snapshot,
                                        paymentMethodName: appModel.paymentMethodName(for: snapshot.paymentMethodId)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("home.quickSnapshot.\(snapshot.category.rawValue)")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .accessibilityIdentifier("home.quickSnapshotsSection")
                }
            }

            if !recentIntents.isEmpty {
                Section("Недавние сценарии") {
                    ForEach(recentIntents) { intent in
                        Button {
                            selectedCategory = intent.context.category
                            selectedChannel = intent.context.channel
                            amountText = decimalString(intent.context.amount)
                            merchantName = intent.context.merchantName ?? ""
                            focusedField = nil
                            presentRecommendation(intent.context)
                        } label: {
                            RecentPurchaseIntentRow(intent: intent)
                        }
                        .accessibilityIdentifier("home.recentIntent.\(intent.context.category.rawValue)")
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
        .sheet(item: $recommendationPresentation) { presentation in
            NavigationStack {
                RecommendationView(context: presentation.context)
            }
        }
        .sheet(isPresented: $isScannerPresented) {
            NavigationStack {
                ScannerView()
            }
        }
        .task {
            presentPendingQuickLaunchIfNeeded()
        }
        .onChange(of: appModel.pendingQuickLaunchContext) { _, _ in
            presentPendingQuickLaunchIfNeeded()
        }
        .onChange(of: appModel.isOnboardingPresented) { _, isPresented in
            guard !isPresented else { return }
            presentPendingQuickLaunchIfNeeded()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button("Показать лучшую оплату") {
                    if let context = makeManualContext() {
                        focusedField = nil
                        presentRecommendation(context)
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

    private var snapshotPreviewAmount: Double {
        guard let normalizedAmount, normalizedAmount > 0 else {
            return 1_000
        }

        return normalizedAmount
    }

    private var usesFallbackSnapshotAmount: Bool {
        guard let normalizedAmount else {
            return true
        }

        return normalizedAmount <= 0
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

    private func presentRecommendation(_ context: PurchaseContext) {
        recommendationPresentation = RecommendationPresentation(context: context)
    }

    private func presentPendingQuickLaunchIfNeeded() {
        guard !appModel.isOnboardingPresented,
              let context = appModel.consumePendingQuickLaunchContext()
        else {
            return
        }

        selectedCategory = context.category
        selectedChannel = context.channel
        amountText = decimalString(context.amount)
        merchantName = context.merchantName ?? ""
        focusedField = nil
        presentRecommendation(context)
    }

    private func decimalString(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(value)
    }
}

private struct QuickRecommendationSnapshotCard: View {
    let snapshot: QuickRecommendationSnapshot
    let paymentMethodName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(snapshot.category.displayName)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(paymentMethodName)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("≈ \(CurrencyFormatter.rubles(snapshot.expectedReward))")
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Text("\(snapshot.expectedPercent.formatted(.number.precision(.fractionLength(0...1))))%")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(width: 190, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct RecentPurchaseIntentRow: View {
    let intent: RecentPurchaseIntent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(intent.context.category.displayName)
                    .font(.headline)

                if let merchantName = intent.context.merchantName {
                    Text(merchantName)
                        .font(.subheadline)
                }

                Text("\(CurrencyFormatter.rubles(intent.context.amount)) · \(intent.context.channel.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if intent.useCount > 1 {
                    Text("\(intent.useCount) раза")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
