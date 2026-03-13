import SwiftUI

struct ScannerView: View {
    private enum UITestDefaults {
        static let isEnabled = ProcessInfo.processInfo.arguments.contains("UITEST_SMOKE")
        static let payload = "sbp://pay?merchant=АЗС Тест&sum=1500"
    }

    @Environment(\.dismiss) private var dismiss
    @State private var payload = UITestDefaults.isEnabled ? UITestDefaults.payload : ""
    @State private var parsed: ParsedQRPayload?

    private let parser = QRParsingService()

    var body: some View {
        Form {
            Section("Scanner shell") {
                Text("На первом проходе здесь остается безопасный shell вместо полноценной AVFoundation-камеры.")
                    .foregroundStyle(.secondary)

                TextField("Вставить raw QR payload", text: $payload, axis: .vertical)
                    .accessibilityIdentifier("scanner.payloadField")
            }

            Section {
                Button("Разобрать payload") {
                    parsed = parser.parse(payload)
                }
                .accessibilityIdentifier("scanner.parseButton")

                Button("Закрыть") {
                    dismiss()
                }
                .accessibilityIdentifier("scanner.closeButton")
            }

            if let parsed {
                Section("Результат") {
                    Text("Канал: \(parsed.channel.displayName)")
                        .accessibilityIdentifier("scanner.result.channel")
                    Text("Amount: \(parsed.amount.map { CurrencyFormatter.rubles($0) } ?? "не найдено")")
                        .accessibilityIdentifier("scanner.result.amount")
                    Text("Merchant: \(parsed.merchantName ?? "не найден")")
                        .accessibilityIdentifier("scanner.result.merchant")
                    Text("Confidence: \(parsed.confidence.formatted(.percent.precision(.fractionLength(0))))")
                        .accessibilityIdentifier("scanner.result.confidence")
                }
            }
        }
        .navigationTitle("QR Scanner")
    }
}
