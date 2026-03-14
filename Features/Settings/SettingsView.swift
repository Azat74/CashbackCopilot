import SwiftUI

struct SettingsView: View {
    private enum UITestDefaults {
        static let isEnabled = ProcessInfo.processInfo.arguments.contains("UITEST_SMOKE")
    }

    private enum ResetAction: String, Identifiable {
        case restoreDemoData
        case wipeLocalData

        var id: String { rawValue }

        var title: String {
            switch self {
            case .restoreDemoData:
                return "Восстановить демо-набор"
            case .wipeLocalData:
                return "Удалить все локальные данные"
            }
        }

        var message: String {
            switch self {
            case .restoreDemoData:
                return "Кошелек, правила, прогресс и история будут заменены демо-набором. После этого onboarding откроется заново."
            case .wipeLocalData:
                return "Приложение очистит локальный кошелек, правила, прогресс и историю. После этого onboarding откроется заново."
            }
        }

        var confirmationTitle: String {
            switch self {
            case .restoreDemoData:
                return "Восстановить"
            case .wipeLocalData:
                return "Удалить"
            }
        }
    }

    @Environment(AppModel.self) private var appModel
    @State private var resetAction: ResetAction?

    var body: some View {
        Form {
            Section("О продукте") {
                Text("Приложение дает рекомендацию, а не гарантирует фактическое начисление кешбека.")
                Text("Все данные в MVP хранятся локально на устройстве.")
            }

            Section("Локальные данные") {
                LabeledContent("Банки", value: "\(appModel.banks.count)")
                    .accessibilityIdentifier("settings.bankCount")
                LabeledContent("Способы оплаты", value: "\(appModel.paymentMethods.count)")
                    .accessibilityIdentifier("settings.paymentMethodCount")
                LabeledContent("Правила кешбэка", value: "\(appModel.rules.count)")
                    .accessibilityIdentifier("settings.ruleCount")
                LabeledContent("Записи в истории", value: "\(appModel.loggedPayments.count)")
                    .accessibilityIdentifier("settings.loggedPaymentCount")
                LabeledContent("Подтверждено фактом", value: confirmedCashbackSummary)
                    .accessibilityIdentifier("settings.confirmedCashbackSummary")
            }

            Section("Privacy") {
                Label("Банковские креды не собираются", systemImage: "lock.shield")
                Label("Raw QR не отправляется наружу", systemImage: "qrcode")
                Label("Внешняя аналитика в MVP отсутствует", systemImage: "chart.bar.xaxis")
            }

            Section("Сервисные действия") {
                if UITestDefaults.isEnabled {
                    wipeLocalDataButton
                }

                Button("Показать onboarding заново") {
                    appModel.replayOnboarding()
                }
                .accessibilityIdentifier("settings.replayOnboardingButton")

                Button("Восстановить демо-набор") {
                    resetAction = .restoreDemoData
                }
                .accessibilityIdentifier("settings.restoreDemoDataButton")
            }

            if !UITestDefaults.isEnabled {
                Section {
                    wipeLocalDataButton
                } header: {
                    Text("Опасная зона")
                } footer: {
                    Text(
                        "Полный reset удалит локальный снимок кошелька, правил, прогресса и истории. " +
                        "Данные не уходят наружу, но текущий локальный state будет потерян."
                    )
                }
            }
        }
        .navigationTitle("Настройки")
        .alert(item: $resetAction) { action in
            Alert(
                title: Text(action.title),
                message: Text(action.message),
                primaryButton: .destructive(Text(action.confirmationTitle)) {
                    switch action {
                    case .restoreDemoData:
                        appModel.restoreDemoData()
                    case .wipeLocalData:
                        appModel.resetLocalData()
                    }
                },
                secondaryButton: .cancel(Text("Отмена"))
            )
        }
    }

    private var confirmedCashbackSummary: String {
        let confirmedCount = appModel.loggedPayments.filter { $0.actualReward != nil }.count
        return "\(confirmedCount) из \(appModel.loggedPayments.count)"
    }

    private var wipeLocalDataButton: some View {
        Button {
            resetAction = .wipeLocalData
        } label: {
            Text("Удалить все локальные данные")
                .accessibilityIdentifier("settings.wipeLocalDataButtonLabel")
        }
        .foregroundStyle(.red)
        .accessibilityIdentifier("settings.wipeLocalDataButton")
    }
}
