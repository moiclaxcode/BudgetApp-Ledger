//
//  EditExpenseTransactionView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/8/25.
//  3/14/25 V1.0 - Working version ? (Time last time a change was made.)

import SwiftUI

struct EditExpenseTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var category: String
    @State private var description: String
    @State private var date: Date
    @State private var amount: String
    @State private var selectedAccountID: UUID
    @State private var selectedLedgerGroup: String
    @State private var selectedSubCategory: String
    @State private var payee: String
    @State private var existingCategories: [String] = []
    @State private var existingSubCategories: [String] = []
    @State private var existingAccounts: [Account] = UserDefaults.standard.getAccounts()
    @State private var showDeleteAlert = false
    var transaction: Transaction
    var onSave: (Transaction) -> Void
    var onDelete: (Transaction) -> Void

    init(transaction: Transaction, onSave: @escaping (Transaction) -> Void, onDelete: @escaping (Transaction) -> Void) {
        self.transaction = transaction
        self.onSave = onSave
        self.onDelete = onDelete
        _category = State(initialValue: transaction.parentCategory) // Updated reference
        _selectedSubCategory = State(initialValue: transaction.subCategory ?? "")
        _selectedLedgerGroup = State(initialValue: transaction.ledgerGroup)
        _description = State(initialValue: transaction.description)
        _date = State(initialValue: transaction.date)
        _amount = State(initialValue: String(abs(transaction.amount))) // ✅ Ensure stored amount is always positive
        _selectedAccountID = State(initialValue: transaction.accountID)
        _payee = State(initialValue: transaction.payee ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Expense Details")) {
                    TextField("Payee", text: $payee)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Description", text: $description)

                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .onChange(of: amount) { _, newValue in
                            amount = newValue.filter { "0123456789.".contains($0) } // ✅ Ensure only valid numbers
                        }

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Picker("Ledger Group", selection: $selectedLedgerGroup) {
                        ForEach(UserDefaults.standard.getLedgers(), id: \.self) { ledger in
                            Text(ledger)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedLedgerGroup) {
                        fetchCategories() // ✅ Load new categories when Ledger Group changes
                        fetchSubCategories() // ✅ Load new subcategories
                    }

                    Picker("Category", selection: $category) {
                        ForEach(existingCategories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: category) {
                        fetchSubCategories() // ✅ Load subcategories for the selected category
                    }

                    Picker("Subcategory", selection: $selectedSubCategory) {
                        ForEach(existingSubCategories, id: \.self) { subCat in
                            Text(subCat).tag(subCat)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.horizontal)
                    .onAppear {
                        fetchCategories()
                        fetchSubCategories()
                    }
                }

                Section(header: Text("Move to Account")) {
                    Picker("Select Account", selection: $selectedAccountID) {
                        ForEach(existingAccounts) { account in
                            Text(account.name).tag(account.id)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Section {
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Text("Delete Expense")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationBarTitle("Edit Expense", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") { saveTransaction() }
            )
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete Expense?"),
                    message: Text("This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        onDelete(transaction) // ✅ Delete the transaction
                        removeTransactionFromStorage(transaction)
                        NotificationCenter.default.post(name: .transactionsUpdated, object: nil) // ✅ Notify all views
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func fetchCategories() {
        existingCategories = CategoryStorage.getCategoriesByLedgerGroup(selectedLedgerGroup)
        if category.isEmpty || !existingCategories.contains(category) {
            category = existingCategories.first ?? "Uncategorized"
        }
    }

    private func fetchSubCategories() {
        existingSubCategories = CategoryStorage.getSubcategories(forCategory: category)
        selectedSubCategory = existingSubCategories.first ?? ""
    }

    private func saveTransaction() {
        guard let transactionAmount = Double(amount), transactionAmount > 0 else { return }

        let updatedTransaction = Transaction(
            id: transaction.id,
            parentCategory: category.isEmpty ? "Uncategorized" : category,
            subCategory: selectedSubCategory,
            description: description,
            date: date,
            amount: -abs(transactionAmount), // ✅ Ensure expenses are saved as negative
            accountID: selectedAccountID,
            type: .expense,
            ledgerGroup: selectedLedgerGroup, // ✅ Ensures transaction is updated under the correct Ledger Group
            payee: payee // ✅ Include payee
        )

        onSave(updatedTransaction)

        var transactions = UserDefaults.standard.savedTransactions
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = updatedTransaction
        }
        UserDefaults.standard.saveTransactions(transactions)

        NotificationCenter.default.post(name: .transactionsUpdated, object: nil) // ✅ Notify all views
        presentationMode.wrappedValue.dismiss()
    }

    private func removeTransactionFromStorage(_ transaction: Transaction) {
        var transactions = UserDefaults.standard.savedTransactions
        transactions.removeAll { $0.id == transaction.id }
        UserDefaults.standard.saveTransactions(transactions)
    }
}
