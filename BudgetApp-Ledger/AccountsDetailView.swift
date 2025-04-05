//
//  AccountsDetailView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/5/25.
//  3/14/25 V1.0 - Working version
//

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
    
    init(ledgerGroup: String = UserDefaults.standard.getLedgers().first ?? "",
         accountStore: AccountStore = AccountStore()) {
        self.ledgerGroup = ledgerGroup
        self._accountStore = ObservedObject(wrappedValue: accountStore)
    }
    
    // MARK: - Computed Properties
    private var filteredAccounts: [Account] {
        accounts.filter { $0.ledgerGroup == ledgerGroup }
    }
    
    private var debitAccounts: [Account] {
        filteredAccounts.filter { ["Debit", "Savings", "Investments", "Cash"].contains($0.type) }
    }
    
    private var creditAccounts: [Account] {
        filteredAccounts.filter { $0.type == "Credit" }
    }
    
    /// Returns the current balance "As of today" for an account, including only transactions with a date <= today.
    /// The logic for each transaction type (expense, income, transfer) mirrors the approach in AccountTransactionsView:
    /// - Debit account:
    ///     • Expense => subtract abs(amount)
    ///     • Income => add abs(amount)
    ///     • Transfer => subtract if sender, add if recipient
    /// - Credit account:
    ///     • Expense => add abs(amount) (debt increases)
    ///     • Income => subtract abs(amount) (debt decreases)
    ///     • Transfer => subtract abs(amount) whether sender or recipient (payments reduce debt)
    /// Finally, we do `openingBalance + transactionTotal` (for both Debit and Credit).
    private func getAccountBalance(_ account: Account) -> Double {
        let transactions = UserDefaults.standard.getTransactions(for: account.id)
        let today = Date()
        // Only include transactions up to and including today.
        let uniqueTransactions = Array(Set(transactions)).filter { $0.date <= today }
        let sortedTransactions = uniqueTransactions.sorted { $0.date < $1.date }
        
        let transactionTotal = sortedTransactions.reduce(0.0) { total, transaction in
            switch transaction.type {
            case .expense:
                if account.type.lowercased() == "credit" {
                    // For credit, expense => +abs => debt up
                    return total + abs(transaction.amount)
                } else {
                    // For debit, expense => -abs => balance down
                    return total - abs(transaction.amount)
                }
                
            case .income:
                if account.type.lowercased() == "credit" {
                    // For credit, income => -abs => debt down
                    return total - abs(transaction.amount)
                } else {
                    // For debit, income => +abs => balance up
                    return total + abs(transaction.amount)
                }
                
            case .transfer:
                // Check if this account is the sender or the recipient
                if let fromID = transaction.fromAccountID, fromID == account.id {
                    // Outgoing transfer => subtract
                    return total - abs(transaction.amount)
                } else if let toID = transaction.toAccountID, toID == account.id {
                    // Incoming transfer => credit => -abs, debit => +abs
                    if account.type.lowercased() == "credit" {
                        return total - abs(transaction.amount)
                    } else {
                        return total + abs(transaction.amount)
                    }
                } else {
                    return total
                }
            }
        }
        
        // Unify the final step for both Debit and Credit, as in AccountTransactionsView
        return account.openingBalance + transactionTotal
    }
    
    private var totalAssets: Double {
        // Summation of as-of-today balances for all debit-type accounts
        debitAccounts.map { getAccountBalance($0) }.reduce(0, +)
    }
    
    private var totalLiabilities: Double {
        // Summation of as-of-today balances for all credit-type accounts
        // We'll treat the final number as a positive liability, so we do abs() here.
        creditAccounts.map { abs(getAccountBalance($0)) }.reduce(0, +)
    }
    
    private var netWorth: Double {
        totalAssets - totalLiabilities
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // MARK: - Header (Pinned at Top)
                VStack(spacing: 0) {
                    HStack {
                        EditButton()
                        Spacer()
                        Text("Accounts")
                            .font(.headline)
                        Spacer()
                        Button(action: { showAddAccountView = true }) {
                            Image(systemName: "plus.circle")
                                .imageScale(.medium)
                                .foregroundColor(
                                    Color(#colorLiteral(red: 0.2980392157, green: 0.3058823529, blue: 0.6078431373, alpha: 0.7994619205))
                                )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    Divider()
                    Text(ledgerGroup)
                        .font(.caption)
                        .foregroundColor(Color(#colorLiteral(red: 0.3294117647, green: 0.3568627451, blue: 0.3921568627, alpha: 1)))
                        .padding(.top, 5)
                    Divider().padding(.horizontal)

                    // MARK: - Net Worth Section
                    VStack(spacing: 5) {
                        Text("Net Worth")
                            .font(.subheadline)
                            .foregroundColor(Color(#colorLiteral(red: 0.949, green: 0.972, blue: 0.992, alpha: 1)))
                        Text("$\(netWorth, specifier: "%.2f")")
                            .font(.title2)
                            .bold()
                            .foregroundColor(Color(#colorLiteral(red: 0.949, green: 0.972, blue: 0.992, alpha: 1)))

                        HStack {
                            VStack {
                                Text("Assets")
                                    .font(.subheadline)
                                    .foregroundColor(Color(#colorLiteral(red: 0.949, green: 0.972, blue: 0.992, alpha: 1)))
                                Text("$\(totalAssets, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(Color(#colorLiteral(red: 0.949, green: 0.972, blue: 0.992, alpha: 1)))
                            }
                            Spacer()
                            VStack {
                                Text("Liabilities")
                                    .font(.subheadline)
                                    .foregroundColor(Color(#colorLiteral(red: 0.949, green: 0.972, blue: 0.992, alpha: 1)))
                                Text("$\(totalLiabilities, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(Color(#colorLiteral(red: 0.949, green: 0.972, blue: 0.992, alpha: 1)))
                            }
                        }
                    }
                    .padding()
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.8025))) // #012169 80% Opacity
                            .stroke(Color.gray.opacity(0.3))
                            .shadow(color: Color(#colorLiteral(red: 0.7804, green: 0.7804, blue: 0.7804, alpha: 0.8006)), radius: 2, y: 1)
                    )
                    .padding()
                    .padding(.top, 5)
                    .padding(.bottom, 5)

                    Divider().padding(.horizontal)
                }
                .background(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))) // F7F7F7
                .zIndex(1)

                // MARK: - Scrollable Transactions in Middle
                ScrollView {
                    VStack(spacing: 10) {
                        // MARK: - Disclosure Groups for Accounts
                        if !debitAccounts.isEmpty {
                            DisclosureGroup(isExpanded: $isDebitExpanded) {
                                ForEach(debitAccounts, id: \.self) { account in
                                    accountRow(account: account)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                        Text("Debit")
                                            .font(.caption)
                                            .foregroundColor(Color(#colorLiteral(red: 0.0039, green: 0.1294, blue: 0.4117, alpha: 0.7995))) // #012169 80% Opacity
                                        Divider()
                                            .frame(width: 40, height: 0.40)
                                            .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                                            .padding(.bottom, 5)
                                    }
                                }
                            
                            .padding(8)
                            .padding(.horizontal, 10)
                            .background(Color.white) // Background for row list
                            .cornerRadius(5)
                            .shadow(color: Color(#colorLiteral(red: 0.7804, green: 0.7804, blue: 0.7804, alpha: 0.8006)), radius: 2, y: 1) // #C7C7C7 80% Opacity
                            
                        }

                        if !creditAccounts.isEmpty {
                            DisclosureGroup(isExpanded: $isCreditExpanded) {
                                ForEach(creditAccounts, id: \.self) { account in
                                    accountRow(account: account)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Credit")
                                        .font(.caption)
                                            .foregroundColor(Color(#colorLiteral(red: 0.8901960784, green: 0.09411764706, blue: 0.2156862745, alpha: 1))) // #E31837
                                        Divider()
                                            .frame(width: 40, height: 0.40)
                                            .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                                            .padding(.bottom, 5)
                                    }
                                }
                           
                            .padding(8)
                            .padding(.horizontal, 10)
                            .background(Color.white) // Background for row list
                            .cornerRadius(5)
                            .shadow(color: Color(#colorLiteral(red: 0.7804, green: 0.7804, blue: 0.7804, alpha: 0.8006)), radius: 2, y: 1) // #C7C7C7 80% Opacity
                            
                        }

                        Spacer(minLength: 120)
                    }
                    .padding()
                    .background(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))) // #F7F7F7 Background behind list
                    .padding(.bottom, 120)
                }

                // MARK: - Footer (Pinned at Bottom)
                Divider()
                    .padding(.bottom,10)
                Divider()
                    .padding(.bottom,10)
                HStack {
                    Spacer()
                    Button(action: { showTransferFundsView = true }) {
                        Image(systemName: "arrow.left.arrow.right.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(Color(#colorLiteral(red: 0.0039, green: 0.1294, blue: 0.4117, alpha: 0.7995))) // #012169 80% Opacity
                    }
                    .padding(.bottom, 10)
                    .padding(.trailing, 20)
                }
            }
        }
            // MARK: - onAppear, onReceive and .sheet section
    
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
            TransferFundsView(accountStore: accountStore) { transaction in
                var transactions = UserDefaults.standard.getTransactions(for: transaction.accountID)
                transactions.append(transaction)
                UserDefaults.standard.saveTransaction(transaction)
                NotificationCenter.default.post(name: .transactionsUpdated, object: nil)
            }
        }
        .sheet(
            isPresented: Binding(
                get: { selectedAccount != nil },
                set: { if !$0 { selectedAccount = nil } }
            )
        ) {
            if let account = selectedAccount {
                AccountTransactionsView(account: account, accountStore: accountStore)
            }
        }
    }
    
    // MARK: - Functions
    private func refreshAccounts() {
        accounts = UserDefaults.standard.getAccounts()
    }
    
    // Helper to show day of month with suffix (e.g. 5th, 21st)
    private func dayOfMonthString(_ date: Date) -> String {
        let dayOfMonth = Calendar.current.component(.day, from: date)
        switch dayOfMonth {
        case 1, 21, 31:
            return "\(dayOfMonth)st"
        case 2, 22:
            return "\(dayOfMonth)nd"
        case 3, 23:
            return "\(dayOfMonth)rd"
        default:
            return "\(dayOfMonth)th"
        }
    }
    
    // MARK: - Subviews
    private func accountRow(account: Account) -> some View {
        Button(action: {
            selectedAccount = account
        }) {
            if account.type.lowercased() == "credit" {
                // Credit Row Layout
                VStack(alignment: .leading, spacing: 4) {
                    // Row 1: Account name (left) and Credit Limit (right)
                    HStack {
                        Text(account.name)
                            .font(.caption)
                            .foregroundColor(
                                Color(#colorLiteral(
                                    red: 0.3294117647,
                                    green: 0.3568627451,
                                    blue: 0.3921568627,
                                    alpha: 0.7987893212
                                ))
                            )
                        Spacer()
                        Text("Limit: $\(account.creditLimit ?? 0, specifier: "%.2f")")
                            .font(.caption2)
                            .foregroundColor(
                                Color(#colorLiteral(
                                    red: 0.5490196078,
                                    green: 0.5960784314,
                                    blue: 0.6549019608,
                                    alpha: 0.8033164321
                                ))
                            )
                    }
                    
                    // Row 2: Due date (left) and Spent amount (right)
                    HStack {
                        if let dueDate = account.dueDate {
                            Text("Due on \(dayOfMonthString(dueDate))")
                                .font(.caption2)
                                .foregroundColor(
                                    Color(#colorLiteral(
                                        red: 0.5490196078,
                                        green: 0.5960784314,
                                        blue: 0.6549019608,
                                        alpha: 0.8033164321
                                    ))
                                )
                        } else {
                            Text("No due date")
                                .font(.caption2)
                                .foregroundColor(
                                    Color(#colorLiteral(
                                        red: 0.5490196078,
                                        green: 0.5960784314,
                                        blue: 0.6549019608,
                                        alpha: 0.8033164321
                                    ))
                                )
                        }
                        Spacer()
                        // Show the 'As of today' credit balance
                        Text("Spent: $\(getAccountBalance(account), specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(
                                Color(#colorLiteral(
                                    red: 0.3294117647,
                                    green: 0.3568627451,
                                    blue: 0.3921568627,
                                    alpha: 0.7987893212
                                ))
                            )
                    }
                    
                    // Row 3: Account description (left) and Available (right)
                    HStack {
                        Text(account.description)
                            .font(.caption2)
                            .foregroundColor(
                                Color(#colorLiteral(
                                    red: 0.5490196078,
                                    green: 0.5960784314,
                                    blue: 0.6549019608,
                                    alpha: 0.8033164321
                                ))
                            )
                        Spacer()
                        let available = (account.creditLimit ?? 0) - getAccountBalance(account)
                        Text("Available: $\(available, specifier: "%.2f")")
                            .font(.caption2)
                            .foregroundColor(
                                Color(#colorLiteral(
                                    red: 0.5490196078,
                                    green: 0.5960784314,
                                    blue: 0.6549019608,
                                    alpha: 0.8033164321
                                ))
                            )
                    }
                    Divider()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
                
            } else {
                // Default Row Layout for Non-Credit Accounts
                VStack(spacing: 2) {
                    HStack {
                        Text(account.name)
                            .font(.caption)
                            .foregroundColor(
                                Color(#colorLiteral(
                                    red: 0.3294117647,
                                    green: 0.3568627451,
                                    blue: 0.3921568627,
                                    alpha: 0.7987893212
                                ))
                            )
                        Spacer()
                        Text("$\(getAccountBalance(account), specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(
                                Color(#colorLiteral(
                                    red: 0.3294117647,
                                    green: 0.3568627451,
                                    blue: 0.3921568627,
                                    alpha: 0.7987893212
                                ))
                            )
                    }
                    HStack {
                        Text(account.description)
                            .font(.caption2)
                            .foregroundColor(
                                Color(#colorLiteral(
                                    red: 0.5490196078,
                                    green: 0.5960784314,
                                    blue: 0.6549019608,
                                    alpha: 0.8011951573
                                ))
                            )
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
}

struct AccountsDetailView_Previews: PreviewProvider {
    static var previews: some View {
        AccountsDetailView(ledgerGroup: "Sample Ledger", accountStore: AccountStore())
    }
}
