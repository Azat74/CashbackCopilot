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
        XCTAssertEqual(appModel.loggedPayments[0].source, .manual)
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
        XCTAssertEqual(appModel.loggedPayments[0].expectedReward, 0)
        XCTAssertFalse(appModel.loggedPayments[0].wasRecommendationUsed)
        XCTAssertTrue(appModel.progress.isEmpty)
    }

    func testRecordQrPaymentStoresQrSource() {
        let bank = Bank(name: "Тест Банк")
        let method = PaymentMethod(bankId: bank.id, displayName: "СБП", type: .sbp)
        let rule = CashbackRule(
            paymentMethodId: method.id,
            title: "QR АЗС 3%",
            category: .fuel,
            percent: 3,
            qrAllowed: true,
            sbpAllowed: true
        )

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [method],
            rules: [rule],
            progress: [],
            loggedPayments: []
        )

        let context = PurchaseContext(
            source: .qr,
            amount: 1_500,
            merchantName: "АЗС Тест",
            category: .fuel,
            channel: .sbp,
            qrPayload: "sbp://pay?merchant=АЗС Тест&sum=1500",
            confidence: 0.75
        )

        let result = RecommendationResult(
            purchaseContextId: context.id,
            bestOption: RecommendationOption(
                paymentMethodId: method.id,
                ruleId: rule.id,
                expectedReward: 45,
                expectedPercent: 3,
                confidence: 0.75,
                reasons: ["QR поддерживается"],
                risks: ["Категория определена предположительно"]
            )
        )

        appModel.recordPayment(for: context, result: result)

        XCTAssertEqual(appModel.loggedPayments.count, 1)
        XCTAssertEqual(appModel.loggedPayments[0].source, .qr)
        XCTAssertEqual(appModel.loggedPayments[0].channel, .sbp)
        XCTAssertEqual(appModel.loggedPayments[0].merchantName, "АЗС Тест")
        XCTAssertEqual(appModel.progress.first?.rewardAccumulated, 45)
    }

    func testConfirmActualCashbackMarksPaymentAsMatched() {
        let payment = LoggedPayment(
            purchaseContextId: UUID(),
            amount: 1_500,
            merchantName: "АЗС",
            source: .manual,
            category: .fuel,
            channel: .card,
            recommendedPaymentMethodId: UUID(),
            actualPaymentMethodId: UUID(),
            expectedReward: 75,
            actualReward: nil,
            wasRecommendationUsed: true
        )

        let appModel = AppModel(
            repository: nil,
            banks: [],
            paymentMethods: [],
            rules: [],
            progress: [],
            loggedPayments: [payment]
        )

        appModel.confirmActualCashback(for: payment.id, amount: 75)

        XCTAssertEqual(appModel.loggedPayments[0].actualReward, 75)
        XCTAssertEqual(appModel.loggedPayments[0].cashbackMatchedExpectation, true)
        XCTAssertEqual(appModel.loggedPayments[0].confirmationStatus, .matched)
    }

    func testConfirmActualCashbackMarksPaymentAsMismatched() {
        let payment = LoggedPayment(
            purchaseContextId: UUID(),
            amount: 1_500,
            merchantName: "АЗС",
            source: .manual,
            category: .fuel,
            channel: .card,
            recommendedPaymentMethodId: UUID(),
            actualPaymentMethodId: UUID(),
            expectedReward: 75,
            actualReward: nil,
            wasRecommendationUsed: true
        )

        let appModel = AppModel(
            repository: nil,
            banks: [],
            paymentMethods: [],
            rules: [],
            progress: [],
            loggedPayments: [payment]
        )

        appModel.confirmActualCashback(for: payment.id, amount: 50)

        XCTAssertEqual(appModel.loggedPayments[0].actualReward, 50)
        XCTAssertEqual(appModel.loggedPayments[0].cashbackMatchedExpectation, false)
        XCTAssertEqual(appModel.loggedPayments[0].confirmationStatus, .mismatched)
    }

    func testReviewLoggedPaymentRecomputesExpectationForCorrectedMethod() {
        let bank = Bank(name: "Тест Банк")
        let recommendedMethod = PaymentMethod(bankId: bank.id, displayName: "Black", type: .debitCard)
        let alternativeMethod = PaymentMethod(bankId: bank.id, displayName: "СБП", type: .sbp)
        let recommendedRule = CashbackRule(paymentMethodId: recommendedMethod.id, title: "АЗС 5%", category: .fuel, percent: 5)
        let alternativeRule = CashbackRule(
            paymentMethodId: alternativeMethod.id,
            title: "АЗС 3%",
            category: .fuel,
            percent: 3,
            sbpAllowed: true
        )

        let payment = LoggedPayment(
            purchaseContextId: UUID(),
            amount: 1_500,
            merchantName: "АЗС",
            source: .manual,
            category: .fuel,
            channel: .card,
            recommendedPaymentMethodId: recommendedMethod.id,
            actualPaymentMethodId: recommendedMethod.id,
            expectedReward: 75,
            actualReward: 45,
            wasRecommendationUsed: true,
            cashbackMatchedExpectation: false,
            appliedRuleId: recommendedRule.id
        )

        let appModel = AppModel(
            repository: nil,
            banks: [bank],
            paymentMethods: [recommendedMethod, alternativeMethod],
            rules: [recommendedRule, alternativeRule],
            progress: [
                SpendProgress(
                    ruleId: recommendedRule.id,
                    monthKey: "2026-03",
                    spentAmount: 1_500,
                    rewardAccumulated: 75
                )
            ],
            loggedPayments: [payment]
        )

        appModel.reviewLoggedPayment(
            for: payment.id,
            category: .fuel,
            actualPaymentMethodID: alternativeMethod.id,
            actualReward: 45
        )

        XCTAssertEqual(appModel.loggedPayments[0].actualPaymentMethodId, alternativeMethod.id)
        XCTAssertEqual(appModel.loggedPayments[0].expectedReward, 45)
        XCTAssertEqual(appModel.loggedPayments[0].actualReward, 45)
        XCTAssertEqual(appModel.loggedPayments[0].appliedRuleId, alternativeRule.id)
        XCTAssertFalse(appModel.loggedPayments[0].wasRecommendationUsed)
        XCTAssertEqual(appModel.loggedPayments[0].confirmationStatus, .matched)
        XCTAssertEqual(appModel.progress.count, 1)
        XCTAssertEqual(appModel.progress[0].ruleId, alternativeRule.id)
        XCTAssertEqual(appModel.progress[0].rewardAccumulated, 45)
    }

    func testRestoreDemoDataReplacesSnapshotAndShowsOnboarding() {
        let appModel = AppModel(repository: nil, banks: [], paymentMethods: [], rules: [], progress: [], loggedPayments: [])
        appModel.isOnboardingPresented = false

        appModel.restoreDemoData()

        XCTAssertEqual(appModel.banks.count, AppSnapshot.demo.banks.count)
        XCTAssertEqual(appModel.paymentMethods.count, AppSnapshot.demo.paymentMethods.count)
        XCTAssertEqual(appModel.rules.count, AppSnapshot.demo.rules.count)
        XCTAssertEqual(appModel.progress.count, AppSnapshot.demo.progress.count)
        XCTAssertEqual(appModel.loggedPayments.count, AppSnapshot.demo.loggedPayments.count)
        XCTAssertTrue(appModel.isOnboardingPresented)
    }

    func testResetLocalDataClearsSnapshotAndShowsOnboarding() {
        let payment = LoggedPayment(
            purchaseContextId: UUID(),
            amount: 999,
            merchantName: "Тест",
            source: .manual,
            category: .other,
            channel: .card,
            recommendedPaymentMethodId: UUID(),
            actualPaymentMethodId: UUID(),
            expectedReward: 12,
            actualReward: 10,
            wasRecommendationUsed: true
        )

        let appModel = AppModel(
            repository: nil,
            banks: AppSnapshot.demo.banks,
            paymentMethods: AppSnapshot.demo.paymentMethods,
            rules: AppSnapshot.demo.rules,
            progress: AppSnapshot.demo.progress,
            loggedPayments: [payment]
        )
        appModel.isOnboardingPresented = false

        appModel.resetLocalData()

        XCTAssertTrue(appModel.banks.isEmpty)
        XCTAssertTrue(appModel.paymentMethods.isEmpty)
        XCTAssertTrue(appModel.rules.isEmpty)
        XCTAssertTrue(appModel.progress.isEmpty)
        XCTAssertTrue(appModel.loggedPayments.isEmpty)
        XCTAssertTrue(appModel.isOnboardingPresented)
    }

    private func tryUnwrap<T>(_ value: T?) -> T {
        guard let value else {
            XCTFail("Expected value to exist")
            fatalError("Missing value")
        }

        return value
    }
}
