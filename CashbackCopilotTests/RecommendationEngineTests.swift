import XCTest
@testable import CashbackCopilot

final class RecommendationEngineTests: XCTestCase {
    private let engine = DefaultRecommendationEngine()

    func testPrefersHigherRewardOption() {
        let bank1 = Bank(name: "Т-Банк")
        let bank2 = Bank(name: "Сбер")

        let method1 = PaymentMethod(bankId: bank1.id, displayName: "Black", type: .debitCard)
        let method2 = PaymentMethod(bankId: bank2.id, displayName: "Classic", type: .debitCard)

        let rule1 = CashbackRule(paymentMethodId: method1.id, title: "АЗС 5%", category: .fuel, percent: 5)
        let rule2 = CashbackRule(paymentMethodId: method2.id, title: "АЗС 1%", category: .fuel, percent: 1)

        let context = PurchaseContext(source: .manual, amount: 2_000, category: .fuel, channel: .card)
        let result = engine.recommend(for: context, paymentMethods: [method1, method2], rules: [rule1, rule2], progress: [])

        XCTAssertEqual(result.bestOption?.paymentMethodId, method1.id)
        XCTAssertEqual(result.bestOption?.expectedReward, 100)
    }

    func testRewardRespectsMonthlyRewardCap() {
        let bank = Bank(name: "Т-Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let rule = CashbackRule(
            paymentMethodId: method.id,
            title: "АЗС 5%",
            category: .fuel,
            percent: 5,
            monthlyRewardCap: 100
        )

        let progress = SpendProgress(ruleId: rule.id, monthKey: "2026-03", spentAmount: 0, rewardAccumulated: 80)
        let context = PurchaseContext(source: .manual, amount: 1_000, category: .fuel, channel: .card)
        let result = engine.recommend(for: context, paymentMethods: [method], rules: [rule], progress: [progress])

        XCTAssertEqual(result.bestOption?.expectedReward, 20)
    }

    func testRewardRespectsMonthlySpendCap() {
        let bank = Bank(name: "Т-Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let rule = CashbackRule(
            paymentMethodId: method.id,
            title: "Продукты 10%",
            category: .groceries,
            percent: 10,
            monthlySpendCap: 1_000
        )

        let progress = SpendProgress(ruleId: rule.id, monthKey: "2026-03", spentAmount: 900, rewardAccumulated: 0)
        let context = PurchaseContext(source: .manual, amount: 500, category: .groceries, channel: .card)
        let result = engine.recommend(for: context, paymentMethods: [method], rules: [rule], progress: [progress])

        XCTAssertEqual(result.bestOption?.expectedReward, 10)
    }
}

