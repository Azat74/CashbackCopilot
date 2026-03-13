import Foundation

protocol HistoryRepository {
    func fetchLoggedPayments() -> [LoggedPayment]
    func saveLoggedPayment(_ payment: LoggedPayment)
}

