import XCTest
@testable import CashbackCopilot

@MainActor
final class AppModelMonthTests: XCTestCase {

    // MARK: - Active Rules Tests

    func testActiveRulesReturnsOnlyMonthScopedRules() {
        let bank = Bank(name: "Тест Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Card", type: .debitCard)

        let rule1 = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5)
        let rule2 = CashbackRule(paymentMethodId: method.id, title: "Продукты 3%", category: .groceries, percent: 3)

        let currentMonth = CashbackMonth(
            bankId: bank.id,
            monthKey: "2026-03",
            ruleStates: [
                RuleState(ruleId: rule1.id, isActive: true, order: 0),
                RuleState(ruleId: rule2.id, isActive: false, order: 1)
            ],
            source: .manual
        )

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [method],
            rules: [rule1, rule2],
            months: [currentMonth],
            progress: [],
            loggedPayments: []
        )

        let activeRules = appModel.activeRules(for: "2026-03")

        XCTAssertEqual(activeRules.count, 1)
        XCTAssertEqual(activeRules.first?.id, rule1.id)
    }

    func testActiveRulesFiltersByBankId() {
        let bank1 = Bank(name: "Банк 1")
        let bank2 = Bank(name: "Банк 2")

        let method1 = PaymentMethod(bankId: bank1.id, displayName: "Card 1", type: .debitCard)
        let method2 = PaymentMethod(bankId: bank2.id, displayName: "Card 2", type: .debitCard)

        let rule1 = CashbackRule(paymentMethodId: method1.id, title: "АЗС 5%", category: .fuel, percent: 5)
        let rule2 = CashbackRule(paymentMethodId: method2.id, title: "АЗС 3%", category: .fuel, percent: 3)

        let month1 = CashbackMonth(
            bankId: bank1.id,
            monthKey: "2026-03",
            ruleStates: [RuleState(ruleId: rule1.id, isActive: true, order: 0)],
            source: .manual
        )

        let month2 = CashbackMonth(
            bankId: bank2.id,
            monthKey: "2026-03",
            ruleStates: [RuleState(ruleId: rule2.id, isActive: true, order: 0)],
            source: .manual
        )

        let appModel = AppModel(
            repository: nil,
            banks: [bank1, bank2],
            paymentMethods: [method1, method2],
            rules: [rule1, rule2],
            months: [month1, month2],
            progress: [],
            loggedPayments: []
        )

        let bank1Rules = appModel.activeRules(for: "2026-03", bankId: bank1.id)

        XCTAssertEqual(bank1Rules.count, 1)
        XCTAssertEqual(bank1Rules.first?.id, rule1.id)
    }

    func testActiveRulesFallbackWhenNoMonthExists() {
        let bank = Bank(name: "Тест Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Card", type: .debitCard)

        let activeRule = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5, isActive: true)
        let inactiveRule = CashbackRule(paymentMethodId: method.id, title: "Продукты 3%", category: .groceries, percent: 3, isActive: false)

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [method],
            rules: [activeRule, inactiveRule],
            months: [],  // No months defined
            progress: [],
            loggedPayments: []
        )

        // When no months exist, should fall back to rule's isActive
        let activeRules = appModel.activeRules(for: "2026-03")

        XCTAssertEqual(activeRules.count, 1)
        XCTAssertEqual(activeRules.first?.id, activeRule.id)
    }

    // MARK: - Month Management Tests

    func testCreateMonth() {
        let bank = Bank(name: "Тест Банк")

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [],
            rules: [],
            months: [],
            progress: [],
            loggedPayments: []
        )

        let newMonth = CashbackMonth(
            bankId: bank.id,
            monthKey: "2026-04",
            ruleStates: [],
            source: .manual
        )

        appModel.createMonth(newMonth)

        XCTAssertEqual(appModel.months.count, 1)
        XCTAssertEqual(appModel.months.first?.id, newMonth.id)
    }

    func testUpdateMonth() {
        let bank = Bank(name: "Тест Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Card", type: .debitCard)
        let rule = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5)

        let originalMonth = CashbackMonth(
            bankId: bank.id,
            monthKey: "2026-03",
            ruleStates: [RuleState(ruleId: rule.id, isActive: true, order: 0)],
            source: .manual
        )

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [method],
            rules: [rule],
            months: [originalMonth],
            progress: [],
            loggedPayments: []
        )

        var updatedMonth = originalMonth
        updatedMonth.ruleStates = [RuleState(ruleId: rule.id, isActive: false, order: 0)]
        updatedMonth.notes = "Updated notes"

        appModel.updateMonth(updatedMonth)

        XCTAssertEqual(appModel.months.count, 1)
        XCTAssertEqual(appModel.months.first?.notes, "Updated notes")
        XCTAssertEqual(appModel.months.first?.ruleStates.first?.isActive, false)
    }

    func testSetRuleActive() {
        let bank = Bank(name: "Тест Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Card", type: .debitCard)
        let rule = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5)

        let month = CashbackMonth(
            bankId: bank.id,
            monthKey: "2026-03",
            ruleStates: [RuleState(ruleId: rule.id, isActive: true, order: 0)],
            source: .manual
        )

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [method],
            rules: [rule],
            months: [month],
            progress: [],
            loggedPayments: []
        )

        appModel.setRuleActive(rule.id, active: false, inMonth: "2026-03", forBank: bank.id)

        let updatedMonth = appModel.month(for: "2026-03", bankId: bank.id)
        XCTAssertFalse(updatedMonth?.ruleStates.first?.isActive ?? true)
    }

    // MARK: - Multiple Months Tests

    func testMultipleMonthsDontInterfere() {
        let bank = Bank(name: "Тест Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Card", type: .debitCard)

        let rule = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5)

        let march = CashbackMonth(
            bankId: bank.id,
            monthKey: "2026-03",
            ruleStates: [RuleState(ruleId: rule.id, isActive: true, order: 0)],
            source: .manual
        )

        let april = CashbackMonth(
            bankId: bank.id,
            monthKey: "2026-04",
            ruleStates: [RuleState(ruleId: rule.id, isActive: false, order: 0)],
            source: .copiedFromPrevious
        )

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [method],
            rules: [rule],
            months: [march, april],
            progress: [],
            loggedPayments: []
        )

        let marchRules = appModel.activeRules(for: "2026-03")
        let aprilRules = appModel.activeRules(for: "2026-04")

        XCTAssertEqual(marchRules.count, 1)
        XCTAssertEqual(aprilRules.count, 0)
    }

    func testMonthsForBankSortedByMonthKey() {
        let bank = Bank(name: "Тест Банк")

        let january = CashbackMonth(bankId: bank.id, monthKey: "2026-01", ruleStates: [], source: .manual)
        let march = CashbackMonth(bankId: bank.id, monthKey: "2026-03", ruleStates: [], source: .manual)
        let february = CashbackMonth(bankId: bank.id, monthKey: "2026-02", ruleStates: [], source: .manual)

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [],
            rules: [],
            months: [january, march, february],
            progress: [],
            loggedPayments: []
        )

        let sortedMonths = appModel.months(for: bank.id)

        XCTAssertEqual(sortedMonths.count, 3)
        XCTAssertEqual(sortedMonths[0].monthKey, "2026-03")
        XCTAssertEqual(sortedMonths[1].monthKey, "2026-02")
        XCTAssertEqual(sortedMonths[2].monthKey, "2026-01")
    }

    // MARK: - Migration Tests

    func testMigrationCreatesCurrentMonthForExistingRules() {
        let bank = Bank(name: "Тест Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Card", type: .debitCard)

        let activeRule = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5, isActive: true)
        let inactiveRule = CashbackRule(paymentMethodId: method.id, title: "Продукты 3%", category: .groceries, percent: 3, isActive: false)

        // Simulate snapshot without months
        let snapshot = AppSnapshot(
            banks: [bank],
            paymentMethods: [method],
            rules: [activeRule, inactiveRule],
            months: [],
            progress: [],
            loggedPayments: []
        )

        let migrated = AppModel.migrateIfNeeded(snapshot: snapshot)

        XCTAssertFalse(migrated.months.isEmpty)
        XCTAssertEqual(migrated.months.count, 1)
        XCTAssertEqual(migrated.months.first?.bankId, bank.id)
        XCTAssertEqual(migrated.months.first?.ruleStates.count, 2)
        XCTAssertEqual(migrated.months.first?.source, .manual)
    }

    func testMigrationPreservesRuleActivationState() {
        let bank = Bank(name: "Тест Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Card", type: .debitCard)

        let activeRule = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5, isActive: true)
        let inactiveRule = CashbackRule(paymentMethodId: method.id, title: "Продукты 3%", category: .groceries, percent: 3, isActive: false)

        let snapshot = AppSnapshot(
            banks: [bank],
            paymentMethods: [method],
            rules: [activeRule, inactiveRule],
            months: [],
            progress: [],
            loggedPayments: []
        )

        let migrated = AppModel.migrateIfNeeded(snapshot: snapshot)

        let activeState = migrated.months.first?.ruleStates.first { $0.ruleId == activeRule.id }
        let inactiveState = migrated.months.first?.ruleStates.first { $0.ruleId == inactiveRule.id }

        XCTAssertTrue(activeState?.isActive ?? false)
        XCTAssertFalse(inactiveState?.isActive ?? true)
    }

    func testMigrationGroupsRulesByBank() {
        let bank1 = Bank(name: "Банк 1")
        let bank2 = Bank(name: "Банк 2")

        let method1 = PaymentMethod(bankId: bank1.id, displayName: "Card 1", type: .debitCard)
        let method2 = PaymentMethod(bankId: bank2.id, displayName: "Card 2", type: .debitCard)

        let rule1 = CashbackRule(paymentMethodId: method1.id, title: "АЗС 5%", category: .fuel, percent: 5)
        let rule2 = CashbackRule(paymentMethodId: method2.id, title: "АЗС 3%", category: .fuel, percent: 3)

        let snapshot = AppSnapshot(
            banks: [bank1, bank2],
            paymentMethods: [method1, method2],
            rules: [rule1, rule2],
            months: [],
            progress: [],
            loggedPayments: []
        )

        let migrated = AppModel.migrateIfNeeded(snapshot: snapshot)

        XCTAssertEqual(migrated.months.count, 2)

        let bank1Month = migrated.months.first { $0.bankId == bank1.id }
        let bank2Month = migrated.months.first { $0.bankId == bank2.id }

        XCTAssertNotNil(bank1Month)
        XCTAssertNotNil(bank2Month)
        XCTAssertEqual(bank1Month?.ruleStates.count, 1)
        XCTAssertEqual(bank2Month?.ruleStates.count, 1)
    }

    func testMigrationSkipsEmptyBanks() {
        let bankWithRules = Bank(name: "Банк с правилами")
        let bankWithoutRules = Bank(name: "Банк без правил")

        let method = PaymentMethod(bankId: bankWithRules.id, displayName: "Card", type: .debitCard)
        let rule = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5)

        let snapshot = AppSnapshot(
            banks: [bankWithRules, bankWithoutRules],
            paymentMethods: [method],
            rules: [rule],
            months: [],
            progress: [],
            loggedPayments: []
        )

        let migrated = AppModel.migrateIfNeeded(snapshot: snapshot)

        XCTAssertEqual(migrated.months.count, 1)
        XCTAssertEqual(migrated.months.first?.bankId, bankWithRules.id)
    }

    // MARK: - Recommendation Integration Tests

    func testRecommendationUsesOnlyCurrentMonthRules() {
        let bank = Bank(name: "Тест Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Card", type: .debitCard)

        let fuelRule = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5)
        let groceriesRule = CashbackRule(paymentMethodId: method.id, title: "Продукты 3%", category: .groceries, percent: 3)

        // Use current month key to avoid date-dependent test failures
        let currentMonthKey = AppModel.monthKey(for: Date())
        let currentMonth = CashbackMonth(
            bankId: bank.id,
            monthKey: currentMonthKey,
            ruleStates: [
                RuleState(ruleId: fuelRule.id, isActive: true, order: 0),
                RuleState(ruleId: groceriesRule.id, isActive: false, order: 1)  // Inactive in current month
            ],
            source: .manual
        )

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [method],
            rules: [fuelRule, groceriesRule],
            months: [currentMonth],
            progress: [],
            loggedPayments: []
        )

        let context = PurchaseContext(source: .manual, amount: 1_000, category: .groceries, channel: .card)
        let result = appModel.makeRecommendation(for: context)

        // Groceries rule is inactive in current month, so no recommendation should be available
        XCTAssertNil(result.bestOption)
    }

    // MARK: - Current Month Key Tests

    func testCurrentMonthKeyFormat() {
        let appModel = AppModel(repository: nil)

        let monthKey = appModel.currentMonthKey

        // Should be in yyyy-MM format
        XCTAssertEqual(monthKey.count, 7)
        XCTAssertTrue(monthKey.contains("-"))
    }
}
