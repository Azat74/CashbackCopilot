import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Form {
            Section("О продукте") {
                Text("Приложение дает рекомендацию, а не гарантирует фактическое начисление кешбека.")
                Text("Все данные в MVP хранятся локально на устройстве.")
            }

            Section("Privacy") {
                Label("Банковские креды не собираются", systemImage: "lock.shield")
                Label("Raw QR не отправляется наружу", systemImage: "qrcode")
                Label("Внешняя аналитика в MVP отсутствует", systemImage: "chart.bar.xaxis")
            }

            Section {
                Button("Сбросить демо-данные") {
                    appModel.resetDemoData()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Настройки")
    }
}

