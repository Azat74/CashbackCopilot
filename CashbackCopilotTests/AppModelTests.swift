import XCTest
@testable import CashbackCopilot

@MainActor
final class AppModelTests: XCTestCase {
    func testAddBankPaymentMethodAndRule() {
        let appModel = AppModel(repository: nil, banks: [], paymentMethods: [], rules: [], progress: [], loggedPayments: [])

        appModel.addBank(name: "Новый банк")
        let bankID = tryUnwrap(appModel.banks.first?.id)

        appModel.addPaymentMethod(
            bankID: bankID,
            displayName: "Основная карта",
            type: .debitCard,
            last4: "5566"
        )
        let methodID = tryUnwrap(appModel.paymentMethods.first?.id)

        appModel.addRule(
            CashbackRule(
                paymentMethodId: methodID,
                title: "Кафе 5%",
                category: .cafes,
                percent: 5,
                monthlyRewardCap: 500,
                qrAllowed: true
            )
        )

        XCTAssertEqual(appModel.banks.count, 1)
        XCTAssertEqual(appModel.paymentMethods.count, 1)
        XCTAssertEqual(appModel.rules.count, 1)
        XCTAssertEqual(appModel.rules.first?.paymentMethodId, methodID)
    }

    func testDeleteBankCascadesToMethodsRulesAndProgress() {
        let bank = Bank(name: "Тест Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let rule = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5)
        let progress = SpendProgress(ruleId: rule.id, monthKey: "2026-03", spentAmount: 1_000, rewardAccumulated: 50)

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [method],
            rules: [rule],
            progress: [progress],
            loggedPayments: []
        )

        appModel.deleteBank(id: bank.id)

        XCTAssertTrue(appModel.banks.isEmpty)
        XCTAssertTrue(appModel.paymentMethods.isEmpty)
        XCTAssertTrue(appModel.rules.isEmpty)
        XCTAssertTrue(appModel.progress.isEmpty)
    }

    func testRecordPaymentStoresPurchaseContextAndUpdatesProgressForRecommendedMethod() {
        let bank = Bank(name: "Тест Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let rule = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5)

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [method],
            rules: [rule],
            progress: [],
            loggedPayments: []
        )

        let context = PurchaseContext(
            source: .manual,
            amount: 2_000,
            merchantName: "АЗС №1",
            category: .fuel,
            channel: .card
        )

        let result = RecommendationResult(
            purchaseContextId: context.id,
            bestOption: RecommendationOption(
                paymentMethodId: method.id,
                ruleId: rule.id,
                expectedReward: 100,
                expectedPercent: 5,
                confidence: 1,
                reasons: ["Категория подходит"],
                risks: []
            )
        )

        appModel.recordPayment(for: context, result: result)

        XCTAssertEqual(appModel.loggedPayments.count, 1)
        XCTAssertEqual(appModel.loggedPayments[0].amount, 2_000)
        XCTAssertEqual(appModel.loggedPayments[0].merchantName, "АЗС №1")
        XCTAssertEqual(appModel.loggedPayments[0].category, .fuel)
        XCTAssertEqual(appModel.loggedPayments[0].channel, .card)
        XCTAssertTrue(appModel.loggedPayments[0].wasRecommendationUsed)
        XCTAssertEqual(appModel.progress.first?.spentAmount, 2_000)
        XCTAssertEqual(appModel.progress.first?.rewardAccumulated, 100)
    }

    func testRecordPaymentWithAlternativeMethodDoesNotUpdateRecommendedRuleProgress() {
        let bank = Bank(name: "Тест Банк")
        let recommendedMethod = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let alternativeMethod = PaymentMethod(bankId: bank.id, displayName: "СБП", type: .sbp)
        let rule = CashbackRule(paymentMethodId: recommendedMethod.id, title: "АЗС 5%", category: .fuel, percent: 5)

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [recommendedMethod, alternativeMethod],
            rules: [rule],
            progress: [],
            loggedPayments: []
        )

        let context = PurchaseContext(
            source: .manual,
            amount: 1_500,
            merchantName: "АЗС №2",
            category: .fuel,
            channel: .card
        )

        let result = RecommendationResult(
            purchaseContextId: context.id,
            bestOption: RecommendationOption(
                paymentMethodId: recommendedMethod.id,
                ruleId: rule.id,
                expectedReward: 75,
                expectedPercent: 5,
                confidence: 1,
                reasons: ["Категория подходит"],
                risks: []
            ),
            alternatives: [
                RecommendationOption(
                    paymentMethodId: alternativeMethod.id,
                    ruleId: nil,
                    expectedReward: 0,
                    expectedPercent: 0,
                    confidence: 1,
                    reasons: [],
                    risks: []
                )
            ]
        )

        appModel.recordPayment(for: context, result: result, actualPaymentMethodID: alternativeMethod.id)

        XCTAssertEqual(appModel.loggedPayments.count, 1)
        XCTAssertEqual(appModel.loggedPayments[0].actualPaymentMethodId, alternativeMethod.id)
        XCTAssertFalse(appModel.loggedPayments[0].wasRecommendationUsed)
        XCTAssertTrue(appModel.progress.isEmpty)
    }

    private func tryUnwrap<T>(_ value: T?) -> T {
        guard let value else {
            XCTFail("Expected value to exist")
            fatalError("Missing value")
        }

        return value
    }
}
