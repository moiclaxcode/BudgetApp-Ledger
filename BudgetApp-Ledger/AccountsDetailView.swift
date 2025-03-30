//
//  AccountsDetailView.swift
//  BudgetApp-Ledger
//  Created by HECTOR on 3/5/25.
//  3/14/25 V1.0 - Working version

import SwiftUI

struct AccountsDetailView: View {
    // MARK: - Properties
    var ledgerGroup: String
    @ObservedObject var accountStore: AccountStore
    @State private var accounts: [Account] = []
    @State private var showAddAccountView = false
    @State private var showTransferFundsView = false
    @State private var selectedAccount: Account?
    
    // Control expanded/collapsed states
    @State private var isDebitExpanded: Bool = true
    @State private var isCreditExpanded: Bool = true
    
    init(ledgerGroup: String = UserDefaults.standard.getLedgers().first ?? "", accountStore: AccountStore = AccountStore()) {
        self.ledgerGroup = ledgerGroup
        self._accountStore = ObservedObject(wrappedValue: accountStore)
    }
    
    // MARK: - Computed Properties
    private var filteredAccounts: [Account] {
        accounts.filter { $0.ledgerGroup == ledgerGroup }
    }
    
    private var debitAccounts: [Account] {
        filteredAccounts.filter { $0.type == "Debit" }
    }
    
    private var creditAccounts: [Account] {
        filteredAccounts.filter { $0.type == "Credit" }
    }
    
    private func getAccountBalance(_ account: Account) -> Double {
        let transactions = UserDefaults.standard.getTransactions(for: account.id)
        let latestTransactions = Array(Set(transactions)).sorted(by: { $0.date < $1.date })
        let transactionTotal = latestTransactions.reduce(0) { total, transaction in
            let amount = abs(transaction.amount)
            return transaction.type.lowercased() == "expense" ? total - amount : total + amount
        }
        return account.openingBalance + transactionTotal
    }
    
    private var totalAssets: Double {
        debitAccounts.map { getAccountBalance($0) }.reduce(0, +)
    }
    
    private var totalLiabilities: Double {
        creditAccounts.map { abs(getAccountBalance($0)) }.reduce(0, +)
    }
    
    private var netWorth: Double {
        totalAssets - totalLiabilities
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            (Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)))
                .edgesIgnoringSafeArea(.all)
            
            // Main Scrollable Content
            ScrollView {
                VStack(spacing: 3) {
                    // MARK: - Header
                    HStack {
                        EditButton()
                        Spacer()
                        Text("Accounts")
                            .font(.headline)
                        Spacer()
                        Button(action: { showAddAccountView = true }) {
                            Image(systemName: "plus.circle")
                                .imageScale(.medium)
                                .foregroundColor(Color(#colorLiteral(red: 0.2980392157, green: 0.3058823529, blue: 0.6078431373, alpha: 0.7994619205)))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Ledger Group Title
                    Divider()
                    Text(ledgerGroup)
                        .font(.caption)
                        .foregroundColor(
                            Color(#colorLiteral(
                                red: 0.3294117647,
                                green: 0.3568627451,
                                blue: 0.3921568627,
                                alpha: 1
                            ))
                        )
                        .padding(.top, 5)
                    Divider().padding (.horizontal)
                    
                    // MARK: - Net Worth Section
                    VStack(spacing: 5) {
                        Text("Net Worth")
                            .font(.subheadline)
                            .foregroundColor(
                                Color(#colorLiteral(
                                    red: 0.9490196078,
                                    green: 0.9725490196,
                                    blue: 0.9921568627,
                                    alpha: 1
                                ))
                            )
                        Text("$\(netWorth, specifier: "%.2f")")
                            .font(.title2)
                            .bold()
                            .foregroundColor(
                                Color(#colorLiteral(
                                    red: 0.9490196078,
                                    green: 0.9725490196,
                                    blue: 0.9921568627,
                                    alpha: 1
                                ))
                            )
                        
                        HStack {
                            VStack {
                                Text("Assets")
                                    .font(.subheadline)
                                    .foregroundColor(
                                        Color(#colorLiteral(
                                            red: 0.9490196078,
                                            green: 0.9725490196,
                                            blue: 0.9921568627,
                                            alpha: 1
                                        ))
                                    )
                                Text("$\(totalAssets, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(
                                        Color(#colorLiteral(
                                            red: 0.9490196078,
                                            green: 0.9725490196,
                                            blue: 0.9921568627,
                                            alpha: 1
                                        ))
                                    )
                            }
                            Spacer()
                            VStack {
                                Text("Liabilities")
                                    .font(.subheadline)
                                    .foregroundColor(
                                        Color(#colorLiteral(
                                            red: 0.9490196078,
                                            green: 0.9725490196,
                                            blue: 0.9921568627,
                                            alpha: 1
                                        ))
                                    )
                                Text("$\(totalLiabilities, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(
                                        Color(#colorLiteral(
                                            red: 0.9490196078,
                                            green: 0.9725490196,
                                            blue: 0.9921568627,
                                            alpha: 1
                                        ))
                                    )
                            }
                        }
                    }
                    .padding()
                    .padding(.horizontal, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995))
                            )
                            .stroke(Color.gray.opacity(0.3))
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                    Divider().padding (.horizontal)
                    
                    // MARK: - Disclosure Groups for Accounts
                    VStack(spacing: 10) {
                        if !debitAccounts.isEmpty {
                            DisclosureGroup(isExpanded: $isDebitExpanded) {
                                ForEach(debitAccounts, id: \.self) { account in
                                    accountRow(account: account)
                                }
                            } label: {
                                HStack {
                                    Text("Debit")
                                        .font(.caption)
                                        .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                                    
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                        
                        if !creditAccounts.isEmpty {
                            DisclosureGroup(isExpanded: $isCreditExpanded) {
                                ForEach(creditAccounts, id: \.self) { account in
                                    accountRow(account: account)
                                }
                            } label: {
                                HStack {
                                    Text("Credit")
                                        .font(.caption)
                                        .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                                    
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1))) // #F7F7F7 Background behind the list
                    
                    Spacer(minLength: 60) // Leave some extra space at bottom so content doesn't get cut off
                }
            }
            
            // MARK: - Pinned Transfer Funds Button
            VStack {
                Spacer()
                Divider()
                HStack {
                    Spacer()
                    Button(action: { showTransferFundsView = true }) {
                        Image(systemName: "arrow.left.arrow.right.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                            
                    }
                    .padding(.bottom, 20)
                    .padding(.trailing, 20)
                }
            }
        }
        .onAppear {
            refreshAccounts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .accountsUpdated)) { _ in
            refreshAccounts()
        }
        .sheet(isPresented: $showAddAccountView, onDismiss: {
            refreshAccounts()
        }) {
            AddAccountView(accountStore: accountStore) { newAccount in
                var storedAccounts = UserDefaults.standard.getAccounts()
                storedAccounts.append(newAccount)
                UserDefaults.standard.saveAccounts(storedAccounts)
                NotificationCenter.default.post(name: .accountsUpdated, object: nil)
            }
        }
        .sheet(isPresented: $showTransferFundsView) {
            TransferFundsView(accountStore: accountStore)
        }
        .sheet(
            isPresented: Binding(
                get: { selectedAccount != nil },
                set: { if !$0 { selectedAccount = nil } }
            )
        ) {
            if let account = selectedAccount {
                AccountTransactionsView(account: account)
            }
        }
    }
    
    // MARK: - Functions
    private func refreshAccounts() {
        accounts = UserDefaults.standard.getAccounts()
    }
    
    private func moveAccount(from source: IndexSet, to destination: Int, in accountType: String) {
        if accountType == "Debit" {
            var updatedAccounts = debitAccounts
            updatedAccounts.move(fromOffsets: source, toOffset: destination)
            updateStoredAccounts(with: updatedAccounts, type: "Debit")
        } else {
            var updatedAccounts = creditAccounts
            updatedAccounts.move(fromOffsets: source, toOffset: destination)
            updateStoredAccounts(with: updatedAccounts, type: "Credit")
        }
    }
    
    private func updateStoredAccounts(with reorderedAccounts: [Account], type: String) {
        var allAccounts = UserDefaults.standard.getAccounts()
        for account in reorderedAccounts {
            if let index = allAccounts.firstIndex(where: { $0.id == account.id }) {
                allAccounts[index] = account
            }
        }
        UserDefaults.standard.saveAccounts(allAccounts)
    }
    
    // MARK: - Subviews
    private func accountRow(account: Account) -> some View {
        Button(action: {
            selectedAccount = account
        }) {
            VStack(spacing: 2) {
                HStack {
                    Text(account.name)
                        .font(.caption)
                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                    Spacer()
                    Text("$\(getAccountBalance(account), specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                }
                HStack {
                    Text(account.description)
                        .font(.caption2)
                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 0.8011951573)))
                    Spacer()
                }
                Divider()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
    }
}

struct AccountsDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AccountsDetailView(ledgerGroup: "Sample Ledger", accountStore: AccountStore())
    }
}
