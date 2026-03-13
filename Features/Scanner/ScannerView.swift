import SwiftUI

struct ScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var payload = ""
    @State private var parsed: ParsedQRPayload?

    private let parser = QRParsingService()

    var body: some View {
        Form {
            Section("Scanner shell") {
                Text("На первом проходе здесь остается безопасный shell вместо полноценной AVFoundation-камеры.")
                    .foregroundStyle(.secondary)

                TextField("Вставить raw QR payload", text: $payload, axis: .vertical)
            }

            Section {
                Button("Разобрать payload") {
                    parsed = parser.parse(payload)
                }

                Button("Закрыть") {
                    dismiss()
                }
            }

            if let parsed {
                Section("Результат") {
                    Text("Канал: \(parsed.channel.displayName)")
                    Text("Amount: \(parsed.amount.map { CurrencyFormatter.rubles($0) } ?? "не найдено")")
                    Text("Merchant: \(parsed.merchantName ?? "не найден")")
                    Text("Confidence: \(parsed.confidence.formatted(.percent.precision(.fractionLength(0))))")
                }
            }
        }
        .navigationTitle("QR Scanner")
    }
}

