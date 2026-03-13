import SwiftUI

struct WalletView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        List {
            ForEach(appModel.banks) { bank in
                Section(bank.name) {
                    let methods = appModel.paymentMethods.filter { $0.bankId == bank.id }
                    let methodIDs = Set(methods.map(\.id))
                    let rules = appModel.rules.filter { methodIDs.contains($0.paymentMethodId) }

                    if methods.isEmpty {
                        Text("Способы оплаты пока не добавлены")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(methods) { method in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(method.displayName)
                                    .font(.headline)

                                Text(method.type.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !rules.isEmpty {
                        ForEach(rules) { rule in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(rule.title)
                                Text(rule.category.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Кошелек")
        .toolbar {
            NavigationLink("Правила") {
                RuleEditorView()
            }
        }
    }
}

