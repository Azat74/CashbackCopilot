import AppIntents
import Foundation

enum QuickRecommendationShortcutCategory: String, AppEnum {
    case groceries
    case fuel
    case cafes
    case taxi
    case marketplaces

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Категория")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .groceries: "Продукты",
        .fuel: "АЗС",
        .cafes: "Кафе",
        .taxi: "Такси",
        .marketplaces: "Маркетплейсы"
    ]

    var cashbackCategory: CashbackCategory {
        switch self {
        case .groceries:
            .groceries
        case .fuel:
            .fuel
        case .cafes:
            .cafes
        case .taxi:
            .taxi
        case .marketplaces:
            .marketplaces
        }
    }
}

enum QuickRecommendationShortcutChannel: String, AppEnum {
    case card
    case qr
    case sbp

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Канал оплаты")
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .card: "Карта",
        .qr: "QR",
        .sbp: "СБП"
    ]

    var paymentChannel: PaymentChannel {
        switch self {
        case .card:
            .card
        case .qr:
            .qr
        case .sbp:
            .sbp
        }
    }
}

struct QuickRecommendationIntent: AppIntent {
    static let title: LocalizedStringResource = "Быстрая рекомендация"
    static let description = IntentDescription("Открывает Cashback Copilot с готовой рекомендацией для выбранной категории.")
    static let openAppWhenRun = true

    @Parameter(title: "Категория", default: .fuel)
    var category: QuickRecommendationShortcutCategory

    @Parameter(title: "Сумма", default: 1_000)
    var amount: Double

    @Parameter(title: "Канал оплаты", default: .card)
    var channel: QuickRecommendationShortcutChannel

    static var parameterSummary: some ParameterSummary {
        Summary("Рекомендация для \(\.$category)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let route = QuickLaunchRoute(
            category: category.cashbackCategory,
            amount: amount > 0 ? amount : QuickLaunchRoute.defaultAmount,
            channel: channel.paymentChannel
        )
        QuickLaunchStore.savePendingRoute(route)
        return .result()
    }
}

struct CashbackCopilotShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickRecommendationIntent(),
            phrases: [
                "\(.applicationName) быстрая рекомендация",
                "Быстрая рекомендация в \(.applicationName)"
            ],
            shortTitle: "Рекомендация",
            systemImageName: "sparkles"
        )
    }
}
