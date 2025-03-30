//
//  EditTransactionView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/5/25.
//  3/14/25 V1.0 - Working version

import SwiftUI

struct EditTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var parentCategory: String
    @State private var description: String
    @State private var date: Date
    @State private var amount: String
    @State private var selectedTransactionType: String
    @State private var selectedAccountID: UUID // ✅ New state to track selected account
    @State private var existingCategories: [String] = ["Food", "Rent", "Utilities", "Salary", "Investment"]
    @State private var existingAccounts: [Account] = UserDefaults.standard.getAccounts() // ✅ Fetch accounts
    @State private var showDeleteAlert = false // ✅ New state for delete confirmation
    var transaction: Transaction
    var onSave: (Transaction) -> Void
    var onDelete: (Transaction) -> Void // ✅ Callback for deleting a transaction

    init(transaction: Transaction, onSave: @escaping (Transaction) -> Void, onDelete: @escaping (Transaction) -> Void) {
        self.transaction = transaction
        self.onSave = onSave
        self.onDelete = onDelete
        _parentCategory = State(initialValue: transaction.parentCategory) // Updated reference
        _description = State(initialValue: transaction.description)
        _date = State(initialValue: transaction.date)
        _amount = State(initialValue: String(abs(transaction.amount))) // ✅ Ensure stored amount is always positive
        _selectedTransactionType = State(initialValue: transaction.type) // ✅ Set default type (Expense/Income)
        _selectedAccountID = State(initialValue: transaction.accountID) // ✅ Set default account
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transaction Details")) {
                    TextField("Description", text: $description)

                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Picker("Category", selection: $parentCategory) {
                        ForEach(existingCategories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                        Text("Other").tag("Other")
                    }
                }

                // ✅ Account Picker (Move Transaction to Another Account)
                Section(header: Text("Move to Account")) {
                    Picker("Select Account", selection: $selectedAccountID) {
                        ForEach(existingAccounts) { account in
                            Text(account.name).tag(account.id)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                // ✅ Fixed Transaction Type Selector (Now Updates Correctly)
                Section(header: Text("Transaction Type")) {
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

                // ✅ Delete Transaction Button
                Section {
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Text("Delete Transaction")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationBarTitle("Edit Transaction", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") { saveTransaction() }
            )
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete Transaction?"),
                    message: Text("This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        onDelete(transaction) // ✅ Call delete function
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    private func saveTransaction() {
        guard let transactionAmount = Double(amount), transactionAmount > 0 else { return }

        let updatedTransaction = Transaction(
            id: transaction.id,
            parentCategory: parentCategory.isEmpty ? "Uncategorized" : parentCategory, // Updated reference
            description: description,
            date: date,
            amount: selectedTransactionType == "Expense" ? -abs(transactionAmount) : abs(transactionAmount), // ✅ Ensure expenses are negative
            accountID: selectedAccountID, // ✅ Assign the selected account
            type: selectedTransactionType // ✅ Ensure correct transaction type
        )

        onSave(updatedTransaction)
        presentationMode.wrappedValue.dismiss()
    }
}
