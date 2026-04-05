import XCTest
@testable import CashbackCopilot

@MainActor
final class AppModelImportDraftTests: XCTestCase {
    func testSaveImportedDraftCreatesScreenshotImportMonthSnapshot() {
        let bank = Bank(name: "Т-Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [method],
            rules: [],
            months: [],
            progress: [],
            loggedPayments: []
        )

        let draft = ParsedCashbackDraft(
            bankId: bank.id,
            bankName: bank.name,
            sourceScreenshotsCount: 2,
            rules: [
                ParsedRuleDraft(
                    title: "АЗС",
                    category: .fuel,
                    percent: 5,
                    specialConditionsText: "Лимит 1000 ₽ в месяц",
                    confidence: 0.75,
                    needsReview: true,
                    sourceScreenshotTitle: "Категории месяца",
                    sourceLine: "АЗС 5%"
                ),
                ParsedRuleDraft(
                    title: "Маркетплейсы",
                    category: .marketplaces,
                    percent: 3,
                    confidence: 0.95,
                    sourceScreenshotTitle: "Категории месяца",
                    sourceLine: "Маркетплейсы 3%"
                )
            ]
        )

        appModel.saveImportedDraft(draft, paymentMethodId: method.id, monthKey: "2026-03")

        XCTAssertEqual(appModel.rules.count, 2)
        XCTAssertEqual(appModel.months.count, 1)
        XCTAssertEqual(appModel.months.first?.source, .screenshotImport)
        XCTAssertEqual(appModel.months.first?.monthKey, "2026-03")
        XCTAssertEqual(appModel.months.first?.ruleStates.count, 2)
        XCTAssertEqual(appModel.activeRules(for: "2026-03", bankId: bank.id).count, 2)
        XCTAssertEqual(
            appModel.activeRules(for: "2026-03", bankId: bank.id).first?.specialConditionsText,
            "Лимит 1000 ₽ в месяц"
        )
        XCTAssertEqual(appModel.months.first?.notes, "Импортировано из 2 скриншотов")
    }

    func testSaveImportedDraftReplacesExistingMonthRuleStatesForBank() {
        let bank = Bank(name: "Т-Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let oldRule = CashbackRule(paymentMethodId: method.id, title: "Старое правило", category: .groceries, percent: 1)
        let oldMonth = CashbackMonth(
            bankId: bank.id,
            monthKey: "2026-03",
            ruleStates: [RuleState(ruleId: oldRule.id, isActive: true, order: 0)],
            source: .manual
        )

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [method],
            rules: [oldRule],
            months: [oldMonth],
            progress: [],
            loggedPayments: []
        )

        let draft = ParsedCashbackDraft(
            bankId: bank.id,
            bankName: bank.name,
            sourceScreenshotsCount: 1,
            rules: [
                ParsedRuleDraft(
                    title: "АЗС",
                    category: .fuel,
                    percent: 5,
                    confidence: 0.95,
                    sourceScreenshotTitle: "Категории месяца",
                    sourceLine: "АЗС 5%"
                )
            ]
        )

        appModel.saveImportedDraft(draft, paymentMethodId: method.id, monthKey: "2026-03")

        let updatedMonth = appModel.month(for: "2026-03", bankId: bank.id)
        XCTAssertEqual(updatedMonth?.source, .screenshotImport)
        XCTAssertEqual(updatedMonth?.ruleStates.count, 1)
        XCTAssertNotEqual(updatedMonth?.ruleStates.first?.ruleId, oldRule.id)
        XCTAssertEqual(appModel.activeRules(for: "2026-03", bankId: bank.id).count, 1)
    }

    func testSaveImportedDraftTrimsEmptySpecialConditions() {
        let bank = Bank(name: "Т-Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [method],
            rules: [],
            months: [],
            progress: [],
            loggedPayments: []
        )

        let draft = ParsedCashbackDraft(
            bankId: bank.id,
            bankName: bank.name,
            sourceScreenshotsCount: 1,
            rules: [
                ParsedRuleDraft(
                    title: "АЗС",
                    category: .fuel,
                    percent: 5,
                    specialConditionsText: "  \n ",
                    confidence: 0.95,
                    sourceScreenshotTitle: "Категории месяца",
                    sourceLine: "АЗС 5%"
                )
            ]
        )

        appModel.saveImportedDraft(draft, paymentMethodId: method.id, monthKey: "2026-03")

        XCTAssertNil(appModel.rules.first?.specialConditionsText)
    }

    func testSaveImportedDraftPreservesUnassignedConditionsInMonthNotes() {
        let bank = Bank(name: "Т-Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [method],
            rules: [],
            months: [],
            progress: [],
            loggedPayments: []
        )

        let draft = ParsedCashbackDraft(
            bankId: bank.id,
            bankName: bank.name,
            sourceScreenshotsCount: 2,
            rules: [
                ParsedRuleDraft(
                    title: "АЗС",
                    category: .fuel,
                    percent: 5,
                    confidence: 0.75,
                    needsReview: true,
                    sourceScreenshotTitle: "Категории месяца",
                    sourceLine: "АЗС 5%"
                )
            ],
            unassignedConditionLines: ["Не действует при оплате по QR"]
        )

        appModel.saveImportedDraft(draft, paymentMethodId: method.id, monthKey: "2026-03")

        XCTAssertEqual(
            appModel.months.first?.notes,
            "Импортировано из 2 скриншотов\nНеразобранные условия:\nНе действует при оплате по QR"
        )
    }
}
