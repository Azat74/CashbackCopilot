import Foundation

enum PaymentMethodType: String, Codable, CaseIterable, Hashable {
    case debitCard
    case creditCard
    case sbp
    case qrOnly
}

struct PaymentMethod: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let bankId: UUID
    var displayName: String
    var type: PaymentMethodType
    var last4: String?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        bankId: UUID,
        displayName: String,
        type: PaymentMethodType,
        last4: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.bankId = bankId
        self.displayName = displayName
        self.type = type
        self.last4 = last4
        self.isActive = isActive
    }
}

