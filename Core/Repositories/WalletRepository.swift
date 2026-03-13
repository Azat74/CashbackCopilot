import Foundation

protocol WalletRepository {
    func fetchBanks() -> [Bank]
    func fetchPaymentMethods() -> [PaymentMethod]
}

