import XCTest
@testable import CashbackCopilot

final class CashbackMonthTests: XCTestCase {

    // MARK: - CashbackMonth Tests

    func testCreateMonthWithRules() {
        let bankId = UUID()
        let ruleId1 = UUID()
        let ruleId2 = UUID()

        let month = CashbackMonth(
            bankId: bankId,
            monthKey: "2026-03",
            ruleStates: [
                RuleState(ruleId: ruleId1, isActive: true, order: 0),
                RuleState(ruleId: ruleId2, isActive: false, order: 1)
            ],
            source: .manual
        )

        XCTAssertEqual(month.bankId, bankId)
        XCTAssertEqual(month.monthKey, "2026-03")
        XCTAssertEqual(month.ruleStates.count, 2)
        XCTAssertEqual(month.source, .manual)
        XCTAssertNil(month.importedAt)
        XCTAssertNil(month.notes)
    }

    func testMonthKeyFormat() {
        let month = CashbackMonth(
            bankId: UUID(),
            monthKey: "2026-03",
            ruleStates: []
        )

        XCTAssertEqual(month.monthKey, "2026-03")
        XCTAssertTrue(month.monthKey.contains("-"))
        XCTAssertEqual(month.monthKey.count, 7)  // "yyyy-MM"
    }

    func testMonthSourceTypes() {
        let manualMonth = CashbackMonth(
            bankId: UUID(),
            monthKey: "2026-03",
            ruleStates: [],
            source: .manual
        )
        XCTAssertEqual(manualMonth.source, .manual)

        let importedMonth = CashbackMonth(
            bankId: UUID(),
            monthKey: "2026-03",
            ruleStates: [],
            source: .screenshotImport,
            importedAt: Date()
        )
        XCTAssertEqual(importedMonth.source, .screenshotImport)
        XCTAssertNotNil(importedMonth.importedAt)

        let copiedMonth = CashbackMonth(
            bankId: UUID(),
            monthKey: "2026-04",
            ruleStates: [],
            source: .copiedFromPrevious
        )
        XCTAssertEqual(copiedMonth.source, .copiedFromPrevious)
    }

    func testMonthEquality() {
        let bankId = UUID()
        let month1 = CashbackMonth(
            id: bankId,
            bankId: bankId,
            monthKey: "2026-03",
            ruleStates: []
        )
        let month2 = CashbackMonth(
            id: bankId,
            bankId: bankId,
            monthKey: "2026-03",
            ruleStates: []
        )

        XCTAssertEqual(month1, month2)
    }

    func testMonthHashable() {
        let bankId = UUID()
        let month1 = CashbackMonth(
            id: bankId,
            bankId: bankId,
            monthKey: "2026-03",
            ruleStates: []
        )
        let month2 = CashbackMonth(
            id: bankId,
            bankId: bankId,
            monthKey: "2026-03",
            ruleStates: []
        )

        var set = Set<CashbackMonth>()
        set.insert(month1)
        set.insert(month2)

        XCTAssertEqual(set.count, 1)
    }

    // MARK: - RuleState Tests

    func testRuleStateInitialization() {
        let ruleId = UUID()
        let state = RuleState(ruleId: ruleId, isActive: true, order: 5)

        XCTAssertEqual(state.ruleId, ruleId)
        XCTAssertEqual(state.isActive, true)
        XCTAssertEqual(state.order, 5)
    }

    func testRuleStateDefaultValues() {
        let ruleId = UUID()
        let state = RuleState(ruleId: ruleId)

        XCTAssertTrue(state.isActive)
        XCTAssertEqual(state.order, 0)
    }

    func testRuleStateIdEqualsRuleId() {
        let ruleId = UUID()
        let state = RuleState(ruleId: ruleId)

        XCTAssertEqual(state.id, ruleId)
    }

    func testRuleStateEquality() {
        let ruleId = UUID()
        let state1 = RuleState(ruleId: ruleId, isActive: true, order: 0)
        let state2 = RuleState(ruleId: ruleId, isActive: true, order: 0)

        XCTAssertEqual(state1, state2)
    }

    func testRuleStateHashable() {
        let ruleId = UUID()
        let state1 = RuleState(ruleId: ruleId, isActive: true, order: 0)
        let state2 = RuleState(ruleId: ruleId, isActive: true, order: 0)

        var set = Set<RuleState>()
        set.insert(state1)
        set.insert(state2)

        XCTAssertEqual(set.count, 1)
    }
}
