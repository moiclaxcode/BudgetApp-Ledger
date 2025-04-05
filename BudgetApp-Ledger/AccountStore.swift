//
//  AccountStore.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/29/25.
//

import Foundation
import SwiftUI

class AccountStore: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var transactions: [Transaction] = []

    init() {
        loadAccounts()
    }

    func loadAccounts() {
        accounts = UserDefaults.standard.getAccounts()
    }

    func addAccount(_ account: Account) {
        accounts.append(account)
        saveAccounts()
    }

    func updateAccount(_ updated: Account) {
        if let index = accounts.firstIndex(where: { $0.id == updated.id }) {
            accounts[index] = updated
            saveAccounts()
        }
    }

    func deleteAccount(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        saveAccounts()
    }

    private func saveAccounts() {
        UserDefaults.standard.saveAccounts(accounts)
    }
}
