import XCTest
@testable import CashbackCopilot

@MainActor
final class AppModelQuickRecommendationSnapshotTests: XCTestCase {
    func testQuickRecommendationSnapshotsUseSameWinnersAsRecommendationEngine() {
        let bank = Bank(name: "Тест Банк")
        let fuelMethod = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let groceriesMethod = PaymentMethod(bankId: bank.id, displayName: "Cashback", type: .creditCard)
        let fuelRule = CashbackRule(paymentMethodId: fuelMethod.id, title: "АЗС 5%", category: .fuel, percent: 5)
        let groceriesRule = CashbackRule(paymentMethodId: groceriesMethod.id, title: "Продукты 7%", category: .groceries, percent: 7)
        let monthKey = AppModel.monthKey(for: Date())
        let month = CashbackMonth(
            bankId: bank.id,
            monthKey: monthKey,
            ruleStates: [
                RuleState(ruleId: fuelRule.id, isActive: true, order: 0),
                RuleState(ruleId: groceriesRule.id, isActive: true, order: 1)
            ],
            source: .manual
        )

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [fuelMethod, groceriesMethod],
            rules: [fuelRule, groceriesRule],
            months: [month],
            progress: [],
            loggedPayments: []
        )

        let snapshots = appModel.quickRecommendationSnapshots(
            amount: 1_500,
            merchantName: nil,
            channel: .card
        )

        XCTAssertEqual(snapshots.map(\.category), [.fuel, .groceries])
        XCTAssertEqual(snapshots.first?.paymentMethodId, fuelMethod.id)
        XCTAssertEqual(snapshots.first?.expectedReward, 75)
        XCTAssertEqual(snapshots.last?.paymentMethodId, groceriesMethod.id)
        XCTAssertEqual(snapshots.last?.expectedReward, 105)
    }

    func testQuickRecommendationSnapshotsUseFallbackAmountWhenManualAmountMissing() throws {
        let bank = Bank(name: "Тест Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let rule = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5)
        let month = CashbackMonth(
            bankId: bank.id,
            monthKey: AppModel.monthKey(for: Date()),
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

        let snapshot = try XCTUnwrap(
            appModel.quickRecommendationSnapshots(amount: nil, merchantName: nil, channel: .card).first
        )

        XCTAssertEqual(snapshot.context.amount, 1_000)
        XCTAssertEqual(snapshot.expectedReward, 50)
    }

    func testQuickRecommendationSnapshotsRespectSelectedChannel() throws {
        let bank = Bank(name: "Тест Банк")
        let cardMethod = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let sbpMethod = PaymentMethod(bankId: bank.id, displayName: "СБП", type: .sbp)
        let cardRule = CashbackRule(paymentMethodId: cardMethod.id, title: "АЗС 5%", category: .fuel, percent: 5)
        let sbpRule = CashbackRule(
            paymentMethodId: sbpMethod.id,
            title: "АЗС СБП 3%",
            category: .fuel,
            percent: 3,
            sbpAllowed: true
        )
        let month = CashbackMonth(
            bankId: bank.id,
            monthKey: AppModel.monthKey(for: Date()),
            ruleStates: [
                RuleState(ruleId: cardRule.id, isActive: true, order: 0),
                RuleState(ruleId: sbpRule.id, isActive: true, order: 1)
            ],
            source: .manual
        )

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [cardMethod, sbpMethod],
            rules: [cardRule, sbpRule],
            months: [month],
            progress: [],
            loggedPayments: []
        )

        let sbpSnapshot = try XCTUnwrap(
            appModel.quickRecommendationSnapshots(amount: 1_500, merchantName: nil, channel: .sbp).first
        )

        XCTAssertEqual(sbpSnapshot.paymentMethodId, sbpMethod.id)
        XCTAssertEqual(sbpSnapshot.expectedReward, 45)
    }
}
