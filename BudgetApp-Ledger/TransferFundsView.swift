//
//  TransferFundsView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/5/25.
//  3/14/25 V1.0 - Working version
//

import SwiftUI

struct TransferFundsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var accountStore: AccountStore
    var existingTransaction: Transaction? = nil
    var onSave: (Transaction) -> Void

    @State private var fromAccountID: UUID?
    @State private var toAccountID: UUID?
    @State private var transferAmount: String = ""
    @State private var transferDate: Date = Date()
    @State private var transferNotes: String = ""
    @State private var showConfirmation = false
    @State private var showDeleteAlert = false

    private var isEditing: Bool { existingTransaction != nil }

    var fromAccount: Account? {
        accountStore.accounts.first(where: { $0.id == fromAccountID })
    }

    var toAccount: Account? {
        accountStore.accounts.first(where: { $0.id == toAccountID })
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1))
                    .edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .center) {
                            Text("Date")
                                .font(.caption)
                                .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                            DatePicker("", selection: $transferDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        VStack(alignment: .center) {
                            Text("Amount")
                                .font(.caption)
                                .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                            TextField("0.00", text: $transferAmount)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .foregroundColor(Color(#colorLiteral(red: 0.0862745098, green: 0.1137254902, blue: 0.1490196078, alpha: 0.8008847268)))
                                .frame(width: 120)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 3)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(5)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .center) {
                            Text("From Account")
                                .font(.caption)
                                .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                            Menu {
                                ForEach(accountStore.accounts) { account in
                                    Button(action: {
                                        fromAccountID = account.id
                                    }) {
                                        Text(account.name)
                                    }
                                }
                            } label: {
                                Text(fromAccount?.name ?? "Select account")
                                    .font(.caption2)
                                    .foregroundColor(Color(#colorLiteral(red: 0.0862745098, green: 0.1137254902, blue: 0.1490196078, alpha: 0.8008847268)))
                                    .frame(width: 120)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 3)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(5)
                            }
                        }
                        
                        VStack(alignment: .center) {
                            Text("To Account")
                                .font(.caption)
                                .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                            Menu {
                                ForEach(accountStore.accounts) { account in
                                    Button(action: {
                                        toAccountID = account.id
                                    }) {
                                        Text(account.name)
                                    }
                                }
                            } label: {
                                Text(toAccount?.name ?? "Select account")
                                    .font(.caption2)
                                    .foregroundColor(Color(#colorLiteral(red: 0.0862745098, green: 0.1137254902, blue: 0.1490196078, alpha: 0.8008847268)))
                                    .frame(width: 120)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 3)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(5)
                            }
                        }
                    }
                    
                    VStack(alignment: .center) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1))) // #8C98A7
                        TextEditor(text: $transferNotes)
                            .frame(height: 100)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)).opacity(0.3))) // #8C98A7
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
                .overlay(
                    Group {
                        if isEditing {
                            Button(action: {
                                showDeleteAlert = true
                            }) {
                                Image(systemName: "trash.circle")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1))) // #8C98A7
                                    .padding()
                            }
                        }
                    },
                    alignment: .bottomTrailing
                )
            }
            .onAppear {
                if let transaction = existingTransaction, fromAccountID == nil {
                    transferDate = transaction.date
                    transferAmount = String(abs(transaction.amount))
                    transferNotes = transaction.notes ?? ""
                    fromAccountID = transaction.fromAccountID ?? transaction.accountID
                    toAccountID = transaction.toAccountID
                    // If no toAccountID, try to deduce it from description:
                    if toAccountID == nil,
                       transaction.description.lowercased().contains("transfer to"),
                       let name = transaction.description.components(separatedBy: "Transfer to ").last,
                       let match = accountStore.accounts.first(where: { $0.name == name }) {
                        toAccountID = match.id
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Transfer Funds")
                        .font(.subheadline)
                        .foregroundColor(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Transfer") { transferFunds() }
                    .disabled(fromAccountID == nil || toAccountID == nil || transferAmount.isEmpty)
            )
            .alert(isPresented: $showConfirmation) {
                Alert(
                    title: Text("Success"),
                    message: Text("Funds transferred successfully!"),
                    dismissButton: .default(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("Delete Transaction"),
                    message: Text("Are you sure you want to delete this transaction?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let transactionToDelete = existingTransaction {
                            var allTransactions = Array(Set(UserDefaults.standard.savedTransactions))
                            allTransactions.removeAll { $0.id == transactionToDelete.id }
                            UserDefaults.standard.saveTransactions(allTransactions)
                        }
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func transferFunds() {
        guard let fromID = fromAccountID,
              let toID = toAccountID,
              let amountValue = Double(transferAmount),
              fromID != toID else {
            return
        }
        
        // Editing branch
        if isEditing, let original = existingTransaction {
            let updated = Transaction(
                id: original.id,
                parentCategory: "Transfer",
                subCategory: nil,
                description: "Transfer to \(toAccount?.name ?? "")",
                date: transferDate,
                amount: -amountValue,
                accountID: fromID,
                type: .transfer,
                isOpeningBalance: false,
                ledgerGroup: fromAccount?.ledgerGroup ?? "General",
                payee: nil,
                notes: transferNotes,
                fromAccountID: fromID,
                toAccountID: toID
            )
            onSave(updated)
            showConfirmation = true
            return
        }
        
        // Non-editing branch: create two transactions
        
        // Update sender: deduct amount
        var updatedAccounts = accountStore.accounts
        if let fromIndex = updatedAccounts.firstIndex(where: { $0.id == fromID }) {
            updatedAccounts[fromIndex].openingBalance -= amountValue
            let fromTransaction = Transaction(
                id: UUID(),
                parentCategory: "Transfer",
                subCategory: nil,
                description: "Transfer to \(toAccount?.name ?? "")",
                date: transferDate,
                amount: -amountValue,
                accountID: fromID,
                type: .transfer,
                isOpeningBalance: false,
                ledgerGroup: fromAccount?.ledgerGroup ?? "General",
                payee: nil,
                notes: transferNotes,
                fromAccountID: fromID,
                toAccountID: toID
            )
            onSave(fromTransaction)
        }
        
        // Update receiver: add amount
        if let toIndex = updatedAccounts.firstIndex(where: { $0.id == toID }) {
            updatedAccounts[toIndex].openingBalance += amountValue
            let toTransaction = Transaction(
                id: UUID(),
                parentCategory: "Transfer",
                subCategory: nil,
                description: "Transfer from \(fromAccount?.name ?? "")",
                date: transferDate,
                amount: amountValue,
                accountID: toID,
                type: .transfer,
                isOpeningBalance: false,
                ledgerGroup: toAccount?.ledgerGroup ?? "General",
                payee: nil,
                notes: transferNotes,
                fromAccountID: fromID,
                toAccountID: toID
            )
            onSave(toTransaction)
        }
        
        accountStore.accounts = updatedAccounts
        showConfirmation = true
    }
}

struct TransferFundsView_Previews: PreviewProvider {
    static var previews: some View {
        TransferFundsView(accountStore: AccountStore(), onSave: { _ in })
    }
}
