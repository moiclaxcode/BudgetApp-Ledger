//
//  TransactionStore.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/28/25.
//

import Foundation
import Combine

class TransactionStore: ObservableObject {
    @Published var transactions: [Transaction] = []

    // Load all transactions for a given account
    func load(for accountID: UUID?) {
        guard let id = accountID else {
            transactions = []
            return
        }
        transactions = UserDefaults.standard.getTransactions(for: id)
    }

    // Load transactions for a specific ledger group
    func load(forLedgerGroup ledgerGroup: String) {
        transactions = UserDefaults.standard.savedTransactions.filter {
            $0.ledgerGroup == ledgerGroup
        }
    }

    // Load all transactions without filtering
    func loadAll() {
        transactions = UserDefaults.standard.savedTransactions
    }

    // Save or update a transaction
    func save(_ transaction: Transaction, for accountID: UUID?) {
        var all = UserDefaults.standard.savedTransactions
        if let index = all.firstIndex(where: { $0.id == transaction.id }) {
            all[index] = transaction
        } else {
            all.append(transaction)
        }
        UserDefaults.standard.saveTransactions(all)

        if let id = accountID {
            load(for: id)
        } else {
            load(forLedgerGroup: transaction.ledgerGroup)
        }
    }

    // Delete a transaction
    func delete(_ transaction: Transaction, for accountID: UUID?) {
        var all = UserDefaults.standard.savedTransactions
        all.removeAll { $0.id == transaction.id }
        UserDefaults.standard.saveTransactions(all)

        if let id = accountID {
            load(for: id)
        } else {
            load(forLedgerGroup: transaction.ledgerGroup)
        }
    }

    // Filter transactions by month and year
    func transactions(forMonth month: Int, year: Int) -> [Transaction] {
        transactions.filter {
            let components = Calendar.current.dateComponents([.month, .year], from: $0.date)
            return components.month == month && components.year == year
        }
    }

    // Filter transactions for future (forecast)
    func futureTransactions(after date: Date = Date()) -> [Transaction] {
        transactions.filter { $0.date > date }
    }

    // Filter transactions up to and including today (for trend)
    func pastAndCurrentTransactions(until date: Date = Date()) -> [Transaction] {
        transactions.filter { $0.date <= date }
    }

    // Filter by ledger group
    func transactions(forLedger ledger: String) -> [Transaction] {
        transactions.filter { $0.ledgerGroup == ledger }
    }
}
