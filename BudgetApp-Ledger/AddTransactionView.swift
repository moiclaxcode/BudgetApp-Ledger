//
//  AddTransactionView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/5/25.
//  Latest update on 3/8/25: Fixed syncing issue between AddTransactionView and ExpenseTransactionView.
//  3/11/25 V1.0 - Working version

import SwiftUI

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    var account: Account? // ✅ Optional account for direct selection

    @State private var category: String = ""
    @State private var description: String = ""
    @State private var date: Date = Date()
    @State private var amount: String = ""
    @State private var selectedTransactionType: String = "Expense"

    @State private var selectedAccountID: UUID?
    @State private var accounts: [Account] = [] // ✅ Fetch accounts dynamically
    @State private var budgetCategories: [String] = [] // ✅ Fetch categories dynamically

    var onSave: (Transaction) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pay From")) { // ✅ Fixed "Pay From" Picker
                    Picker("Select Account", selection: $selectedAccountID) {
                        ForEach(accounts, id: \.id) { account in
                            Text(account.name).tag(account.id as UUID?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle()) // ✅ Ensures Picker is interactive
                }

                Section(header: Text("Transaction Details")) {
                    TextField("Description", text: $description)

                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .onChange(of: amount) { _, newValue in
                            amount = newValue.filter { "0123456789.".contains($0) } // ✅ Allow only valid numbers
                        }

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Picker("Category", selection: $category) { // ✅ Fixed Category Picker
                        ForEach(budgetCategories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(MenuPickerStyle()) // ✅ Ensures Picker is interactive
                }

                Section(header: Text("Transaction Type")) { // ✅ Fixed Transaction Type Selector
                    HStack {
                        Button(action: { selectedTransactionType = "Expense" }) {
                            Text("Expense")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(selectedTransactionType == "Expense" ? Color.red.opacity(0.3) : Color.clear)
                                .cornerRadius(8)
                        }
                        .foregroundColor(.black)

                        Button(action: { selectedTransactionType = "Income" }) {
                            Text("Income")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(selectedTransactionType == "Income" ? Color.green.opacity(0.3) : Color.clear)
                                .cornerRadius(8)
                        }
                        .foregroundColor(.black)
                    }
                    .buttonStyle(PlainButtonStyle()) // ✅ Ensures button press updates state immediately
                }
            }
            .navigationBarTitle("Add Transaction", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") { saveTransaction() }
            )
            .onAppear {
                fetchAccounts()
                fetchCategories()

                DispatchQueue.main.async {
                    // ✅ Ensure a valid category selection
                    if category.isEmpty || !budgetCategories.contains(category) {
                        category = budgetCategories.first ?? "Other"
                    }

                    // ✅ If an account was passed, use it as the default
                    if let account = account {
                        selectedAccountID = account.id
                    } else if selectedAccountID == nil || !accounts.contains(where: { $0.id == selectedAccountID }) {
                        selectedAccountID = accounts.first?.id
                    }
                }
            }
        }
    }

    private func fetchAccounts() { // ✅ Fetch available accounts
        accounts = UserDefaults.standard.savedAccounts // ✅ Fetch from UserDefaults

        // ✅ Ensure there is always a valid selected account
        if selectedAccountID == nil || !accounts.contains(where: { $0.id == selectedAccountID }) {
            selectedAccountID = accounts.first?.id
        }
    }

    private func fetchCategories() {
        let budgets = CategoryStorage.getBudgets() // ✅ Fetch from the new storage system
        let categories = budgets.compactMap { (budget: Budget) -> String? in budget.parentCategory }.filter { !$0.isEmpty } // ✅ Updated reference
        
        if !categories.isEmpty {
            budgetCategories = Array(Set(categories)).sorted() // ✅ Ensure unique and sorted categories
            
            // ✅ Ensure category has a valid default selection
            if category.isEmpty || !budgetCategories.contains(category) {
                category = budgetCategories.first ?? "Other"
            }
        } else {
            budgetCategories = ["Other"] // ✅ Fallback category to prevent empty picker
            category = "Other" // ✅ Ensures valid default selection
        }
    }

    private func saveTransaction() {
        guard let transactionAmount = Double(amount), transactionAmount > 0 else { return }
        guard let selectedAccountID = selectedAccountID else { return } // ✅ Ensure account ID is valid

        let newTransaction = Transaction(
            id: UUID(),
            parentCategory: category.isEmpty ? "Uncategorized" : category, // ✅ Updated reference
            description: description,
            date: date,
            amount: selectedTransactionType == "Expense" ? -abs(transactionAmount) : abs(transactionAmount), // ✅ Ensure expenses are negative
            accountID: selectedAccountID, // ✅ Updated to reflect selected account
            type: selectedTransactionType
        )

        onSave(newTransaction)

        var transactions = UserDefaults.standard.savedTransactions // ✅ Fetch existing transactions
        transactions.append(newTransaction) // ✅ Append new transaction
        UserDefaults.standard.saveTransactions(transactions) // ✅ Save transactions properly

        // ✅ Notify views that a new transaction was added
        NotificationCenter.default.post(name: .transactionUpdated, object: nil)

        presentationMode.wrappedValue.dismiss() // ✅ Close the sheet after saving
    }
}

// ✅ Define Notification Names to sync transactions across views
extension Notification.Name {
    static let transactionUpdated = Notification.Name("transactionUpdated") // ✅ Unified transaction update event
}
