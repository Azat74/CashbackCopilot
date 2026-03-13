import XCTest
@testable import CashbackCopilot

final class RecommendationRegressionTests: XCTestCase {
    private let engine = DefaultRecommendationEngine()

    func testFuelScenarioPrefersTBankOverLowerRewardCard() {
        let bank1 = Bank(name: "Т-Банк")
        let bank2 = Bank(name: "Сбер")

        let method1 = PaymentMethod(bankId: bank1.id, displayName: "Black", type: .debitCard)
        let method2 = PaymentMethod(bankId: bank2.id, displayName: "Classic", type: .debitCard)

        let rule1 = CashbackRule(paymentMethodId: method1.id, title: "АЗС 5%", category: .fuel, percent: 5)
        let rule2 = CashbackRule(paymentMethodId: method2.id, title: "АЗС 1%", category: .fuel, percent: 1)

        let context = PurchaseContext(source: .manual, amount: 2_000, category: .fuel, channel: .card)
        let result = engine.recommend(for: context, paymentMethods: [method1, method2], rules: [rule1, rule2], progress: [])

        XCTAssertEqual(result.bestOption?.paymentMethodId, method1.id)
    }

    func testQrScenarioExcludesRuleWithoutQrSupport() {
        let bank = Bank(name: "Т-Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let rule = CashbackRule(paymentMethodId: method.id, title: "Продукты 5%", category: .groceries, percent: 5, qrAllowed: false)

        let context = PurchaseContext(source: .qr, amount: 1_500, category: .groceries, channel: .qr)
        let result = engine.recommend(for: context, paymentMethods: [method], rules: [rule], progress: [])

        XCTAssertNil(result.bestOption)
    }

    func testNoMatchingCategoryReturnsEmptyRecommendation() {
        let bank = Bank(name: "Т-Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let rule = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5)

        let context = PurchaseContext(source: .manual, amount: 500, category: .pharmacy, channel: .card)
        let result = engine.recommend(for: context, paymentMethods: [method], rules: [rule], progress: [])

        XCTAssertFalse(result.hasRecommendation)
    }
}

