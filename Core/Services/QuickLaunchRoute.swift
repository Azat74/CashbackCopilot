import Foundation

struct QuickLaunchRoute: Equatable {
    static let scheme = "cashbackcopilot"
    static let recommendHost = "recommend"
    static let defaultAmount = 1_000.0

    var category: CashbackCategory
    var amount: Double
    var merchantName: String?
    var channel: PaymentChannel

    init(
        category: CashbackCategory,
        amount: Double = Self.defaultAmount,
        merchantName: String? = nil,
        channel: PaymentChannel = .card
    ) {
        self.category = category
        self.amount = amount
        self.merchantName = merchantName
        self.channel = channel
    }

    init?(url: URL) {
        guard url.scheme == Self.scheme,
              url.host == Self.recommendHost,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return nil
        }

        let query = (components.queryItems ?? []).reduce(into: [String: String]()) { result, item in
            guard let value = item.value else {
                return
            }

            result[item.name] = value
        }

        guard let rawCategory = query["category"],
              let category = CashbackCategory(rawValue: rawCategory)
        else {
            return nil
        }

        let amount = query["amount"].flatMap(Double.init) ?? Self.defaultAmount
        let channel = query["channel"].flatMap(PaymentChannel.init(rawValue:)) ?? .card
        let merchantName = query["merchant"]?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard amount > 0 else {
            return nil
        }

        self.init(
            category: category,
            amount: amount,
            merchantName: merchantName?.isEmpty == true ? nil : merchantName,
            channel: channel
        )
    }

    var url: URL {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.recommendHost
        components.queryItems = [
            URLQueryItem(name: "category", value: category.rawValue),
            URLQueryItem(name: "amount", value: String(amount)),
            URLQueryItem(name: "channel", value: channel.rawValue)
        ]

        if let merchantName, !merchantName.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "merchant", value: merchantName))
        }

        return components.url!
    }

    var context: PurchaseContext {
        PurchaseContext(
            source: .manual,
            amount: amount,
            merchantName: merchantName,
            category: category,
            channel: channel,
            confidence: 0.8
        )
    }
}

enum QuickLaunchStore {
    private static let pendingURLKey = "quickLaunch.pendingRecommendationURL"

    static func savePendingRoute(_ route: QuickLaunchRoute) {
        UserDefaults.standard.set(route.url.absoluteString, forKey: pendingURLKey)
    }

    static func consumePendingRoute() -> QuickLaunchRoute? {
        guard let urlString = UserDefaults.standard.string(forKey: pendingURLKey),
              let url = URL(string: urlString)
        else {
            return nil
        }

        UserDefaults.standard.removeObject(forKey: pendingURLKey)
        return QuickLaunchRoute(url: url)
    }
}
