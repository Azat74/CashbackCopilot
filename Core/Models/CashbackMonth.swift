import Foundation

/// Represents the source of a monthly snapshot's rules.
enum MonthSource: String, Codable, CaseIterable {
    /// Manually created by the user
    case manual
    /// Imported from bank app screenshots
    case screenshotImport
    /// Copied from a previous month during transition
    case copiedFromPrevious
}

/// Represents the activation state of a rule within a specific month.
struct RuleState: Identifiable, Codable, Equatable, Hashable {
    var id: UUID { ruleId }

    let ruleId: UUID
    var isActive: Bool
    var order: Int

    init(
        ruleId: UUID,
        isActive: Bool = true,
        order: Int = 0
    ) {
        self.ruleId = ruleId
        self.isActive = isActive
        self.order = order
    }
}

/// A monthly snapshot of cashback rules for a specific bank.
///
/// `CashbackMonth` is a first-class entity that groups rule activation states
/// for a specific bank and month. The recommendation engine uses only the
/// active rules from the current month's snapshot, ensuring historical rules
/// don't interfere with current recommendations.
///
/// - Note: Rules themselves are global definitions. This entity only stores
///   which rules are active for this specific month.
struct CashbackMonth: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let bankId: UUID

    /// Month identifier in "yyyy-MM" format
    let monthKey: String

    /// Rule activation states for this month
    var ruleStates: [RuleState]

    /// How this month's rules were sourced
    var source: MonthSource

    /// When this month was imported (for screenshot imports)
    var importedAt: Date?

    /// Optional user notes for this month
    var notes: String?

    init(
        id: UUID = UUID(),
        bankId: UUID,
        monthKey: String,
        ruleStates: [RuleState] = [],
        source: MonthSource = .manual,
        importedAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.bankId = bankId
        self.monthKey = monthKey
        self.ruleStates = ruleStates
        self.source = source
        self.importedAt = importedAt
        self.notes = notes
    }
}
