import XCTest
@testable import CashbackCopilot

final class BusinessGuardrailsTests: XCTestCase {
    private let engine = DefaultRecommendationEngine()

    func testNoValidRulesReturnsNoRecommendation() {
        let context = PurchaseContext(source: .manual, amount: 1_000, category: .fuel, channel: .card)
        let result = engine.recommend(for: context, paymentMethods: [], rules: [], progress: [])

        XCTAssertFalse(result.hasRecommendation)
        XCTAssertNil(result.bestOption)
        XCTAssertTrue(result.alternatives.isEmpty)
    }

    func testUnsupportedChannelCannotBeRecommended() {
        let bank = Bank(name: "Т-Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let rule = CashbackRule(
            paymentMethodId: method.id,
            title: "АЗС 5%",
            category: .fuel,
            percent: 5,
            qrAllowed: false
        )

        let context = PurchaseContext(source: .qr, amount: 1_000, category: .fuel, channel: .qr)
        let result = engine.recommend(for: context, paymentMethods: [method], rules: [rule], progress: [])

        XCTAssertNil(result.bestOption)
    }

    func testConfidenceIsClampedToZeroOneRange() {
        let bank = Bank(name: "Т-Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let rule = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5)
        let context = PurchaseContext(source: .manual, amount: 1_000, category: .fuel, channel: .card, confidence: 5)

        let result = engine.recommend(for: context, paymentMethods: [method], rules: [rule], progress: [])
        XCTAssertEqual(result.bestOption?.confidence, 1)
    }

    func testUncertainResultContainsRisks() {
        let bank = Bank(name: "Т-Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let rule = CashbackRule(paymentMethodId: method.id, title: "АЗС 5%", category: .fuel, percent: 5)
        let context = PurchaseContext(
            source: .qr,
            amount: 1_000,
            merchantName: nil,
            category: .fuel,
            channel: .card,
            confidence: 0.6
        )

        let result = engine.recommend(for: context, paymentMethods: [method], rules: [rule], progress: [])
        XCTAssertFalse(result.bestOption?.risks.isEmpty ?? true)
    }
}

