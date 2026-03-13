import Foundation
import SwiftData

@MainActor
final class LocalSnapshotRepository: WalletRepository, RulesRepository, ProgressRepository, HistoryRepository {
    private let context: ModelContext
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(context: ModelContext) {
        self.context = context
    }

    func seedIfNeeded(with snapshot: AppSnapshot = .demo) {
        guard record() == nil else {
            return
        }

        saveSnapshot(snapshot)
    }

    func loadSnapshot() -> AppSnapshot {
        guard let record = record(),
              let snapshot = try? decoder.decode(AppSnapshot.self, from: record.payload) else {
            return .demo
        }

        return snapshot
    }

    func saveSnapshot(_ snapshot: AppSnapshot) {
        guard let payload = try? encoder.encode(snapshot) else {
            return
        }

        if let existing = record() {
            existing.payload = payload
            existing.updatedAt = .now
        } else {
            let newRecord = AppSnapshotRecord(payload: payload)
            context.insert(newRecord)
        }

        try? context.save()
    }

    func fetchBanks() -> [Bank] {
        loadSnapshot().banks
    }

    func fetchPaymentMethods() -> [PaymentMethod] {
        loadSnapshot().paymentMethods
    }

    func fetchRules() -> [CashbackRule] {
        loadSnapshot().rules
    }

    func fetchProgress() -> [SpendProgress] {
        loadSnapshot().progress
    }

    func fetchLoggedPayments() -> [LoggedPayment] {
        loadSnapshot().loggedPayments
    }

    func saveLoggedPayment(_ payment: LoggedPayment) {
        var snapshot = loadSnapshot()
        snapshot.loggedPayments.insert(payment, at: 0)
        saveSnapshot(snapshot)
    }

    private func record() -> AppSnapshotRecord? {
        let descriptor = FetchDescriptor<AppSnapshotRecord>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return try? context.fetch(descriptor).first
    }
}

