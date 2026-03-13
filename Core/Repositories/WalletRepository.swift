import Foundation

@MainActor
protocol WalletRepository {
    func fetchBanks() -> [Bank]
    func fetchPaymentMethods() -> [PaymentMethod]
}
