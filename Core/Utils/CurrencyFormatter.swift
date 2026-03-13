import Foundation

enum CurrencyFormatter {
    static func rubles(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "RUB"
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSNumber(value: value)) ?? "\(value) ₽"
    }
}

