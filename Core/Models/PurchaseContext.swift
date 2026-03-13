import Foundation

enum PurchaseSource: String, Codable, Hashable {
    case manual
    case qr

    var displayName: String {
        switch self {
        case .manual:
            "Ручной ввод"
        case .qr:
            "QR"
        }
    }
}

enum PaymentChannel: String, Codable, CaseIterable, Hashable {
    case card
    case qr
    case sbp

    var displayName: String {
        switch self {
        case .card:
            "Карта"
        case .qr:
            "QR"
        case .sbp:
            "СБП"
        }
    }
}

struct PurchaseContext: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var source: PurchaseSource
    var amount: Double
    var merchantName: String?
    var category: CashbackCategory
    var channel: PaymentChannel
    var qrPayload: String?
    var confidence: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        source: PurchaseSource,
        amount: Double,
        merchantName: String? = nil,
        category: CashbackCategory,
        channel: PaymentChannel,
        qrPayload: String? = nil,
        confidence: Double = 1.0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.source = source
        self.amount = amount
        self.merchantName = merchantName
        self.category = category
        self.channel = channel
        self.qrPayload = qrPayload
        self.confidence = confidence
        self.createdAt = createdAt
    }
}
