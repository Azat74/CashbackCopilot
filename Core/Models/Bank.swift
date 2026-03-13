import Foundation

struct Bank: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var iconName: String?
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.isActive = isActive
    }
}

