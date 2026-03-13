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

    private func tryUnwrap<T>(_ value: T?) -> T {
        guard let value else {
            XCTFail("Expected value to exist")
            fatalError("Missing value")
        }

        return value
    }
}
