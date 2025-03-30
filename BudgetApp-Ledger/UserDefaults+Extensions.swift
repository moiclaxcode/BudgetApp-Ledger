//
//  UserDefaults+Extensions.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/4/25.
//  3/14/25 V1.0 - Working version (Vital File)

import Foundation

extension UserDefaults {
    private static let accountsKey = "accounts"
    private static let ledgersKey = "ledgers"
    private static let transactionsKey = "transactions"
    private static let expenseTransactionsKey = "expenseTransactions" // ✅ New Key for Expense Transactions
    private static let incomeTransactionsKey = "incomeTransactions" // ✅ New Key for Income Transactions

    // MARK: - Account Functions
    var savedAccounts: [Account] {
        get {
            if let data = data(forKey: Self.accountsKey),
               let accounts = try? JSONDecoder().decode([Account].self, from: data) {
                return accounts
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Self.accountsKey)
            }
        }
    }

    func getAccounts() -> [Account] {
        return savedAccounts
    }

    func getAccount(for id: UUID) -> Account? {
        return savedAccounts.first { $0.id == id }
    }

    func saveAccounts(_ accounts: [Account]) {
        savedAccounts = accounts
        NotificationCenter.default.post(name: .accountsUpdated, object: nil)
    }

    func saveAccount(_ account: Account) {
        var accounts = savedAccounts

        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
        } else {
            accounts.append(account)
        }

        saveAccounts(accounts)
    }

    func deleteAccount(_ account: Account) {
        var accounts = savedAccounts
        accounts.removeAll { $0.id == account.id }
        saveAccounts(accounts)

        // ✅ Remove all transactions linked to the deleted account
        var transactions = savedTransactions
        transactions.removeAll { $0.accountID == account.id }
        saveTransactions(transactions)

        // ✅ Notify other views to update dynamically
        NotificationCenter.default.post(name: .accountsUpdated, object: nil)
    }

    // MARK: - Ledger Functions
    var savedLedgers: [String] {
        get {
            if let ledgers = array(forKey: Self.ledgersKey) as? [String] {
                return ledgers
            }
            return []
        }
        set {
            set(newValue, forKey: Self.ledgersKey)
        }
    }

    func getLedgers() -> [String] {
        return savedLedgers
    }

    func saveLedgers(_ ledgers: [String]) {
        savedLedgers = ledgers
    }

    func saveLedger(_ ledger: String) {
        var ledgers = savedLedgers
        if !ledgers.contains(ledger) {
            ledgers.append(ledger)
            savedLedgers = ledgers
        }
    }

    // MARK: - Transaction Functions
    var savedTransactions: [Transaction] {
        get {
            if let data = data(forKey: Self.transactionsKey),
               let transactions = try? JSONDecoder().decode([Transaction].self, from: data) {
                return transactions
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Self.transactionsKey)
            }
        }
    }

    func getTransactions(for accountID: UUID) -> [Transaction] {
        return savedTransactions.filter { $0.accountID == accountID }
    }
    
    func getAllAccountTransactions() -> [Transaction] {
        return savedTransactions // ✅ Fetch all transactions from accounts
    }

    func getTransactions(for ledgerGroup: String) -> [Transaction] {
        // Normalize the ledger group string to ensure consistent filtering
        let normalizedLedger = ledgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        let expenseTransactions = savedExpenseTransactions.filter {
            $0.ledgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalizedLedger
        }
        let incomeTransactions = savedIncomeTransactions.filter {
            $0.ledgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalizedLedger
        }
        let accountTransactions = savedTransactions.filter {
            $0.ledgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalizedLedger
        }

        // Merge transactions from all sources
        return Array(Set(expenseTransactions + incomeTransactions + accountTransactions))
    }

    func saveTransactions(_ transactions: [Transaction]) {
        savedTransactions = transactions
    }

    func saveTransaction(_ transaction: Transaction) {
        var transactions = savedTransactions
        transactions.append(transaction)
        saveTransactions(transactions)
    }

    func deleteTransaction(_ transaction: Transaction) {
        var transactions = savedTransactions
        transactions.removeAll { $0.id == transaction.id }
        saveTransactions(transactions)
    }

    func saveAccountTransactions(_ transactions: [Transaction], for accountID: UUID) {
        // Remove any existing transactions for the account
        var currentTransactions = savedTransactions.filter { $0.accountID != accountID }
        // Append the new transactions
        currentTransactions.append(contentsOf: transactions)
        saveTransactions(currentTransactions)
    }

    // MARK: - Expense Transactions (Newly Added)
    var savedExpenseTransactions: [Transaction] {
        get {
            if let data = data(forKey: Self.expenseTransactionsKey),
               let transactions = try? JSONDecoder().decode([Transaction].self, from: data) {
                return transactions
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Self.expenseTransactionsKey)
            }
        }
    }

    func getExpenseTransactions() -> [Transaction] {
        return savedExpenseTransactions
    }

    func saveExpenseTransactions(_ transactions: [Transaction]) {
        savedExpenseTransactions = transactions
    }

    func saveExpenseTransaction(_ transaction: Transaction, ledgerGroup: String) {
        var transactions = savedExpenseTransactions

        // ✅ Ensure the transaction is assigned to the correct ledger group
        var newTransaction = transaction
        newTransaction.ledgerGroup = ledgerGroup

        transactions.append(newTransaction)
        saveExpenseTransactions(transactions)

        // ✅ Notify views to refresh
        NotificationCenter.default.post(name: .transactionsUpdated, object: nil)
    }

    // MARK: - Income Transactions (Newly Added)
    var savedIncomeTransactions: [Transaction] {
        get {
            if let data = data(forKey: Self.incomeTransactionsKey),
               let transactions = try? JSONDecoder().decode([Transaction].self, from: data) {
                return transactions
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                set(data, forKey: Self.incomeTransactionsKey)
            }
        }
    }

    func getIncomeTransactions() -> [Transaction] {
        return savedIncomeTransactions
    }

    func saveIncomeTransactions(_ transactions: [Transaction]) {
        savedIncomeTransactions = transactions
    }

    func saveIncomeTransaction(_ transaction: Transaction, ledgerGroup: String) {
        var transactions = savedIncomeTransactions
        
        // ✅ Assign ledger group to the transaction
        var newTransaction = transaction
        newTransaction.ledgerGroup = ledgerGroup

        transactions.append(newTransaction)
        saveIncomeTransactions(transactions)

        // ✅ Notify views to refresh
        NotificationCenter.default.post(name: .transactionsUpdated, object: nil)
    }

    func deleteIncomeTransaction(_ transaction: Transaction) {
        var transactions = savedIncomeTransactions
        transactions.removeAll { $0.id == transaction.id }
        saveIncomeTransactions(transactions)
    }

    // MARK: - Reset App Data
    func resetAppData() {
        dictionaryRepresentation().keys.forEach { removeObject(forKey: $0) }

        // ✅ Explicitly clear transactions and expenses
        removeObject(forKey: Self.transactionsKey)
        removeObject(forKey: Self.expenseTransactionsKey) // ✅ Clear expense transactions
        removeObject(forKey: Self.incomeTransactionsKey) // ✅ Clear income transactions

        // ✅ Clear in-memory data to prevent old data from appearing
        savedLedgers = []
        savedAccounts = []
        savedTransactions = []
        savedExpenseTransactions = []
        savedIncomeTransactions = []

        synchronize() // ✅ Ensures data is cleared immediately
        
        // ✅ Ensure CategoryStorage data is also cleared
        CategoryStorage.clearAllData()

        // ✅ Notify UI to refresh
        NotificationCenter.default.post(name: .accountsUpdated, object: nil)
        NotificationCenter.default.post(name: .transactionsUpdated, object: nil)
    }
}

extension Notification.Name {
    static let accountsUpdated = Notification.Name("accountsUpdated")
    static let transactionsUpdated = Notification.Name("transactionsUpdated") // ✅ Notify when expenses update
}
