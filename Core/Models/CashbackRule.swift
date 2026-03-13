import Foundation

enum CashbackCategory: String, Codable, CaseIterable, Hashable {
    case groceries
    case fuel
    case cafes
    case restaurants
    case taxi
    case pharmacy
    case marketplaces
    case travel
    case transport
    case other

    var displayName: String {
        switch self {
        case .groceries:
            "Продукты"
        case .fuel:
            "АЗС"
        case .cafes:
            "Кафе"
        case .restaurants:
            "Рестораны"
        case .taxi:
            "Такси"
        case .pharmacy:
            "Аптеки"
        case .marketplaces:
            "Маркетплейсы"
        case .travel:
            "Путешествия"
        case .transport:
            "Транспорт"
        case .other:
            "Другое"
        }
    }
}

struct CashbackRule: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let paymentMethodId: UUID

    var title: String
    var category: CashbackCategory

    var percent: Double?
    var fixedReward: Double?

    var minAmount: Double?
    var monthlyRewardCap: Double?
    var monthlySpendCap: Double?

    var qrAllowed: Bool
    var sbpAllowed: Bool

    var includedMCCs: [String]
    var excludedMCCs: [String]
    var merchantIncludes: [String]
    var merchantExcludes: [String]

    var excludeIfMixedWithOtherPromo: Bool
    var priority: Int
    var isActive: Bool

    init(
        id: UUID = UUID(),
        paymentMethodId: UUID,
        title: String,
        category: CashbackCategory,
        percent: Double? = nil,
        fixedReward: Double? = nil,
        minAmount: Double? = nil,
        monthlyRewardCap: Double? = nil,
        monthlySpendCap: Double? = nil,
        qrAllowed: Bool = false,
        sbpAllowed: Bool = false,
        includedMCCs: [String] = [],
        excludedMCCs: [String] = [],
        merchantIncludes: [String] = [],
        merchantExcludes: [String] = [],
        excludeIfMixedWithOtherPromo: Bool = false,
        priority: Int = 0,
        isActive: Bool = true
    ) {
        self.id = id
        self.paymentMethodId = paymentMethodId
        self.title = title
        self.category = category
        self.percent = percent
        self.fixedReward = fixedReward
        self.minAmount = minAmount
        self.monthlyRewardCap = monthlyRewardCap
        self.monthlySpendCap = monthlySpendCap
        self.qrAllowed = qrAllowed
        self.sbpAllowed = sbpAllowed
        self.includedMCCs = includedMCCs
        self.excludedMCCs = excludedMCCs
        self.merchantIncludes = merchantIncludes
        self.merchantExcludes = merchantExcludes
        self.excludeIfMixedWithOtherPromo = excludeIfMixedWithOtherPromo
        self.priority = priority
        self.isActive = isActive
    }
}

