import SwiftUI

struct ConfirmPurchaseContextView: View {
    var body: some View {
        Form {
            Section("Подтверждение контекста") {
                Text("Этот экран зарезервирован под подтверждение суммы, категории и канала после QR-скана.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Подтвердить контекст")
    }
}

