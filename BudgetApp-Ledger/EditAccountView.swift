//
//  EditAccountView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/3/25.
//  3/14/25 V1.0 - Working version

import SwiftUI

struct EditAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var accountName: String
    @State private var accountType: String
    @State private var description: String
    @State private var openingBalance: String
    @State private var asOfDate: Date
    @State private var ledgerGroup: String
    @State private var selectedLedger: String
    @State private var existingLedgers: [String] = UserDefaults.standard.getLedgers()
    @State private var selectedEmoji: String = "💰"
    @State private var showConfirmation = false // ✅ New state for confirmation alert

    var onSave: (Account) -> Void
    var account: Account

    init(account: Account, onSave: @escaping (Account) -> Void) {
        self.account = account
        self.onSave = onSave
        _accountName = State(initialValue: account.name)
        _accountType = State(initialValue: account.type)
        _description = State(initialValue: account.description)
        _openingBalance = State(initialValue: String(account.openingBalance))
        _asOfDate = State(initialValue: account.asOfDate)
        _ledgerGroup = State(initialValue: account.ledgerGroup)
        _selectedLedger = State(initialValue: account.ledgerGroup)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Details")) {
                    TextField("Account Name", text: $accountName)

                    Picker("Account Type", selection: $accountType) {
                        Text("Debit").tag("Debit")
                        Text("Credit").tag("Credit")
                    }
                    .pickerStyle(MenuPickerStyle())

                    TextField("Description", text: $description)

                    TextField("Opening Balance", text: $openingBalance)
                        .keyboardType(.decimalPad)

                    DatePicker("As of Date", selection: $asOfDate, displayedComponents: .date)
                }

                Section(header: Text("Ledger Group")) {
                    Picker("Select Ledger", selection: $selectedLedger) {
                        ForEach(existingLedgers, id: \.self) { ledger in
                            Text(ledger).tag(ledger)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Section(header: Text("Account Icon")) {
                    HStack {
                        Text("Select an Emoji:")
                        TextField("💰", text: $selectedEmoji)
                            .frame(width: 50)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .navigationBarTitle("Edit Account", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") {
                    saveAccount()
                }
            )
            .alert(isPresented: $showConfirmation) { // ✅ Show confirmation alert
                Alert(title: Text("Success"), message: Text("Account updated successfully"), dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }

    private func saveAccount() {
        guard let balance = Double(openingBalance) else { return }

        let updatedAccount = Account(
            id: account.id,
            name: accountName,
            type: accountType,
            description: description,
            openingBalance: balance,
            asOfDate: asOfDate,
            ledgerGroup: selectedLedger
        )

        onSave(updatedAccount)
        showConfirmation = true // ✅ Trigger confirmation alert
    }
}
