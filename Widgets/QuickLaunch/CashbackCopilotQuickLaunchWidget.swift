import SwiftUI
import WidgetKit

struct QuickLaunchEntry: TimelineEntry {
    let date: Date
}

struct QuickLaunchProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickLaunchEntry {
        QuickLaunchEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickLaunchEntry) -> Void) {
        completion(QuickLaunchEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLaunchEntry>) -> Void) {
        completion(Timeline(entries: [QuickLaunchEntry(date: Date())], policy: .never))
    }
}

struct CashbackCopilotQuickLaunchWidget: Widget {
    let kind = "CashbackCopilotQuickLaunchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickLaunchProvider()) { entry in
            QuickLaunchWidgetView(entry: entry)
        }
        .configurationDisplayName("Быстрая рекомендация")
        .description("Открывает Cashback Copilot сразу с популярной категорией покупки.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct QuickLaunchWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: QuickLaunchEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Cashback", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.primary)

            if family == .systemSmall {
                VStack(spacing: 8) {
                    quickLink(.fuel)
                    quickLink(.groceries)
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    quickLink(.fuel)
                    quickLink(.groceries)
                    quickLink(.cafes)
                    quickLink(.taxi)
                }
            }
        }
        .containerBackground(.background, for: .widget)
    }

    private func quickLink(_ category: WidgetQuickCategory) -> some View {
        Link(destination: category.url) {
            HStack(spacing: 6) {
                Image(systemName: category.systemImageName)
                Text(category.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 34)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }
}

enum WidgetQuickCategory: String, CaseIterable {
    case fuel
    case groceries
    case cafes
    case taxi

    var title: String {
        switch self {
        case .fuel:
            "АЗС"
        case .groceries:
            "Продукты"
        case .cafes:
            "Кафе"
        case .taxi:
            "Такси"
        }
    }

    var systemImageName: String {
        switch self {
        case .fuel:
            "fuelpump"
        case .groceries:
            "cart"
        case .cafes:
            "cup.and.saucer"
        case .taxi:
            "car"
        }
    }

    var url: URL {
        URL(string: "cashbackcopilot://recommend?category=\(rawValue)&amount=1000&channel=card")!
    }
}

@main
struct CashbackCopilotWidgetBundle: WidgetBundle {
    var body: some Widget {
        CashbackCopilotQuickLaunchWidget()
    }
}
