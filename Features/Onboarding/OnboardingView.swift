import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Spacer()

                Text("Cashback Copilot")
                    .font(.largeTitle.bold())

                VStack(alignment: .leading, spacing: 12) {
                    Label("Подсказывает, чем выгоднее платить перед покупкой", systemImage: "sparkles")
                    Label("Учитывает категории, лимиты и ограничения", systemImage: "checkmark.seal")
                    Label("Не требует логинов и паролей банков", systemImage: "lock.shield")
                }
                .font(.headline)

                Text("В MVP приложение работает локально и выдает объяснимую рекомендацию, а не обещание банкового начисления.")
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Начать") {
                    appModel.isOnboardingPresented = false
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier("onboarding.startButton")
            }
            .padding(24)
        }
    }
}
