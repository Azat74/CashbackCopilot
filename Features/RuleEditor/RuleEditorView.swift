import SwiftUI

struct RuleEditorView: View {
    var body: some View {
        Form {
            Section("Rule Editor") {
                Text("Полноценный редактор правил будет следующим шагом. Сейчас структура экрана уже заведена в проект.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Правила")
    }
}

