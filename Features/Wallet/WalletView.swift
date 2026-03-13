import SwiftUI

struct WalletView: View {
    @Environment(AppModel.self) private var appModel
    @State private var isAddBankPresented = false
    @State private var bankForNewMethod: Bank?

    var body: some View {
        List {
            if appModel.banks.isEmpty {
                EmptyStateView(
                    title: "Кошелек пока пустой",
                    message: "Добавьте банк, затем способ оплаты и правило кешбека.",
                    systemImage: "wallet.pass"
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(appModel.banks) { bank in
                    Section {
                        let methods = appModel.paymentMethods(for: bank.id)

                        if methods.isEmpty {
                            Text("Способы оплаты пока не добавлены")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(methods) { method in
                                WalletMethodCard(method: method)
                            }
                        }

                        Button {
                            bankForNewMethod = bank
                        } label: {
                            Label("Добавить способ оплаты", systemImage: "plus.circle")
                        }
                    } header: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(bank.name)
                                Text("\(appModel.paymentMethods(for: bank.id).count) способов оплаты")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(role: .destructive) {
                                appModel.deleteBank(id: bank.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
        }
        .animation(.default, value: appModel.banks)
        .animation(.default, value: appModel.paymentMethods)
        .animation(.default, value: appModel.rules)
        .navigationTitle("Кошелек")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink("Правила") {
                    RuleEditorView()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddBankPresented = true
                } label: {
                    Label("Добавить банк", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddBankPresented) {
            NavigationStack {
                AddBankView()
            }
        }
        .sheet(item: $bankForNewMethod) { bank in
            NavigationStack {
                AddPaymentMethodView(bank: bank)
            }
        }
    }
}

private struct WalletMethodCard: View {
    @Environment(AppModel.self) private var appModel
    let method: PaymentMethod

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.displayName)
                        .font(.headline)

                    Text(methodSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(role: .destructive) {
                    appModel.deletePaymentMethod(id: method.id)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }

            let methodRules = appModel.rules(for: method.id)
            if methodRules.isEmpty {
                Text("Для этого способа оплаты еще нет правил.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(methodRules) { rule in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(rule.title)
                                .font(.subheadline.weight(.medium))

                            Text(ruleSummary(rule))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button(role: .destructive) {
                            appModel.deleteRule(id: rule.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            NavigationLink {
                RuleEditorView(preselectedPaymentMethodID: method.id)
            } label: {
                Label("Добавить правило", systemImage: "plus.circle")
                    .font(.subheadline.weight(.medium))
            }
        }
        .padding(.vertical, 4)
    }

    private var methodSubtitle: String {
        if let last4 = method.last4, !last4.isEmpty {
            return "\(method.type.displayName) · •••• \(last4)"
        }

        return method.type.displayName
    }

    private func ruleSummary(_ rule: CashbackRule) -> String {
        let rewardValue: String
        if let percent = rule.percent {
            rewardValue = "\(Int(percent))%"
        } else if let fixedReward = rule.fixedReward {
            rewardValue = "\(Int(fixedReward)) ₽"
        } else {
            rewardValue = "Без выгоды"
        }

        return "\(rule.category.displayName) · \(rewardValue)"
    }
}

private struct AddBankView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var iconName = "building.columns"

    var body: some View {
        Form {
            Section("Новый банк") {
                TextField("Название банка", text: $name)
                TextField("SF Symbol иконки", text: $iconName)
            }
        }
        .navigationTitle("Добавить банк")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Отмена") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    appModel.addBank(name: name, iconName: iconName.isEmpty ? nil : iconName)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

private struct AddPaymentMethodView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let bank: Bank

    @State private var displayName = ""
    @State private var type: PaymentMethodType = .debitCard
    @State private var last4 = ""

    var body: some View {
        Form {
            Section("Банк") {
                Text(bank.name)
            }

            Section("Способ оплаты") {
                TextField("Название", text: $displayName)

                Picker("Тип", selection: $type) {
                    ForEach(PaymentMethodType.allCases, id: \.self) { item in
                        Text(item.displayName).tag(item)
                    }
                }

                TextField("Последние 4 цифры", text: $last4)
                    .keyboardType(.numberPad)
            }
        }
        .navigationTitle("Новый способ оплаты")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Отмена") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Сохранить") {
                    appModel.addPaymentMethod(
                        bankID: bank.id,
                        displayName: displayName,
                        type: type,
                        last4: last4
                    )
                    dismiss()
                }
                .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack {
        WalletView()
    }
    .environment(PreviewContainer.appModel)
}
