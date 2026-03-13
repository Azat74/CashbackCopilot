import Foundation

@MainActor
protocol HistoryRepository {
    func fetchLoggedPayments() -> [LoggedPayment]
    func saveLoggedPayment(_ payment: LoggedPayment)
}
