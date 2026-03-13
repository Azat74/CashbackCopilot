import Foundation

enum MockData {
    static let tBank = Bank(name: "Т-Банк", iconName: "banknote")
    static let alfa = Bank(name: "Альфа", iconName: "creditcard")

    static let methods: [PaymentMethod] = [
        PaymentMethod(bankId: tBank.id, displayName: "Black", type: .debitCard, last4: "1234"),
        PaymentMethod(bankId: tBank.id, displayName: "СБП", type: .sbp),
        PaymentMethod(bankId: alfa.id, displayName: "Cashback", type: .creditCard, last4: "4242")
    ]

    static let rules: [CashbackRule] = [
        CashbackRule(
            paymentMethodId: methods[0].id,
            title: "АЗС 5%",
            category: .fuel,
            percent: 5,
            monthlyRewardCap: 1_000,
            qrAllowed: false,
            sbpAllowed: false
        ),
        CashbackRule(
            paymentMethodId: methods[1].id,
            title: "QR АЗС 3%",
            category: .fuel,
            percent: 3,
            monthlyRewardCap: 600,
            qrAllowed: true,
            sbpAllowed: true
        ),
        CashbackRule(
            paymentMethodId: methods[2].id,
            title: "Продукты 7%",
            category: .groceries,
            percent: 7,
            monthlyRewardCap: 1_500,
            qrAllowed: true
        )
    ]

    static let progress: [SpendProgress] = [
        SpendProgress(ruleId: rules[0].id, monthKey: "2026-03", spentAmount: 8_000, rewardAccumulated: 400),
        SpendProgress(ruleId: rules[2].id, monthKey: "2026-03", spentAmount: 5_000, rewardAccumulated: 350)
    ]

    static let sampleContext = PurchaseContext(
        source: .manual,
        amount: 1_500,
        merchantName: "АЗС",
        category: .fuel,
        channel: .card,
        confidence: 1.0
    )
}

