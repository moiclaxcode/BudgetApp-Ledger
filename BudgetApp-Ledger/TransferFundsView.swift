//
//  TransferFundsView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/5/25.
//  3/14/25 V1.0 - Working version

import SwiftUI

struct TransferFundsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var accountStore: AccountStore
    @State private var fromAccountID: UUID?
    @State private var toAccountID: UUID?
    @State private var transferAmount: String = ""
    @State private var transferDate: Date = Date()
    @State private var transferNotes: String = ""
    @State private var showConfirmation = false

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
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width:120)
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
                                    .frame(width:120)
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
                                    .frame(width:120)
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
                            .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                        TextEditor(text: $transferNotes)
                            .frame(height: 100)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)).opacity(0.3)))
                    }

                    Spacer()
                }
                .padding(.horizontal, 40)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Transfer Funds")
                        .font(.subheadline) // or use .custom("YourFontName", size: ...)
                        .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995))) // customize the color here
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
        }
    }

    private func transferFunds() {
        guard let fromID = fromAccountID,
              let toID = toAccountID,
              let amountValue = Double(transferAmount),
              fromID != toID else {
            return
        }

        var updatedAccounts = accountStore.accounts

        // Deduct from sender
        if let fromIndex = updatedAccounts.firstIndex(where: { $0.id == fromID }) {
            updatedAccounts[fromIndex].openingBalance -= amountValue
        }

        // Add to receiver
        if let toIndex = updatedAccounts.firstIndex(where: { $0.id == toID }) {
            updatedAccounts[toIndex].openingBalance += amountValue
        }

        // Save updated accounts
        accountStore.accounts = updatedAccounts

        // Show confirmation
        showConfirmation = true
    }
}

//Preview
struct TransferFundsView_Previews: PreviewProvider {
    static var previews: some View {
        TransferFundsView(accountStore: AccountStore())
    }
}
