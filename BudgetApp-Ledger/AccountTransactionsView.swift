//
//  AccountTransactionsView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/5/25.
//  3/14/25 V1.0 - Working version

import SwiftUI

struct AccountTransactionsView: View {
    // MARK: - Properties
    var account: Account
    @StateObject private var transactionStore = TransactionStore()
    @State private var showAddTransactionView = false
    @State private var showAddIncomeView = false
    @State private var showEditTransactionView = false
    @State private var selectedTransaction: Transaction?
    // Add this new state property in the Properties section:
    @State private var disclosureExpandedStates: [String: Bool] = [:]
    
    // We only have two grouping modes now: Day and Month
    @State private var selectedGrouping: String = "Month"
    
    init(account: Account) {
        self.account = account
    }
    
    // MARK: - Computed Properties
    
    private var accountBalance: Double {
        let uniqueTransactions = Array(Set(transactionStore.transactions))
        let transactionTotal = uniqueTransactions.reduce(0) { total, transaction in
            let amount = abs(transaction.amount)
            return transaction.type.lowercased() == "expense" ? total - amount : total + amount
        }
        return account.openingBalance + transactionTotal
    }
    
    private func calculateSubBalance(for transaction: Transaction) -> Double {
        var balance = account.openingBalance
        // Sort ascending by date so we can accumulate up to the given transaction
        let uniqueTransactions = Array(Set(transactionStore.transactions)).sorted { $0.date < $1.date }
        
        for trans in uniqueTransactions {
            let amount = abs(trans.amount)
            balance += trans.type.lowercased() == "expense" ? -amount : amount
            if trans.id == transaction.id {
                return balance
            }
        }
        return balance
    }
    
    // MARK: - Grouped Transactions Computed Property
    private var groupedTransactions: [(group: String, transactions: [Transaction])] {
        // Sort descending so newer transactions are at the top
        let uniqueTransactions = Array(Set(transactionStore.transactions))
        let sortedTransactions = uniqueTransactions.sorted { $0.date > $1.date }
        
        var groups: [Date: [Transaction]] = [:]
        let calendar = Calendar.current
        
        // 1) Determine the 'groupDate' for each transaction based on Day or Month
        for transaction in sortedTransactions {
            let date = transaction.date
            var groupDate: Date
            
            switch selectedGrouping {
            case "Day":
                // groupDate is the start of that calendar day
                groupDate = calendar.startOfDay(for: date)
            default: // "Month"
                // groupDate is the start of that month (year + month, day=1)
                let components = calendar.dateComponents([.year, .month], from: date)
                groupDate = calendar.date(from: components) ?? date
            }
            
            groups[groupDate, default: []].append(transaction)
        }
        
        // 2) Sort the dictionary keys (which are Dates) in descending order
        let sortedKeys = groups.keys.sorted(by: >)
        
        // 3) Convert each key Date to a display string, and return array of (group, transactions)
        return sortedKeys.map { key -> (group: String, transactions: [Transaction]) in
            let dateFormatter = DateFormatter()
            switch selectedGrouping {
            case "Day":
                dateFormatter.dateFormat = "EEE, MMM d" // e.g. "Sat, Mar 25"
            default: // "Month"
                dateFormatter.dateFormat = "MMM"        // e.g. "Mar"
            }
            let groupString = dateFormatter.string(from: key)
            return (group: groupString, transactions: groups[key] ?? [])
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            (Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1))) // #F7F7F7
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                
                // MARK: - Header (Pinned at Top)
                VStack(spacing: 0) {
                    // Account Header
                    VStack {
                        Text(account.name)
                            .font(.title2)
                            .bold()
                            .foregroundColor(
                                Color(#colorLiteral(
                                    red: 0.3294117647,
                                    green: 0.3568627451,
                                    blue: 0.3921568627,
                                    alpha: 1
                                ))
                            )
                        Divider()
                        Text(account.ledgerGroup)
                            .font(.caption)
                            .foregroundColor(
                                Color(#colorLiteral(
                                    red: 0.3294117647,
                                    green: 0.3568627451,
                                    blue: 0.3921568627,
                                    alpha: 1
                                ))
                            )
                        Divider().padding(.horizontal)
                    }
                    .padding(.top, 5)
                    
                    // Balance & Action Buttons
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Balance")
                                    .font(.caption)
                                    .foregroundColor(
                                        Color(#colorLiteral(
                                            red: 0.9490196078,
                                            green: 0.9725490196,
                                            blue: 0.9921568627,
                                            alpha: 1
                                        ))
                                    )
                                Text("$\(accountBalance, specifier: "%.2f")")
                                    .font(.title3)
                                    .bold()
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
                            
                            HStack {
                                // Income
                                Button(action: {
                                    selectedTransaction = nil
                                    showAddIncomeView.toggle()
                                }) {
                                    Image(systemName: "arrow.down.circle")
                                        .font(.system(size: 30))
                                        .foregroundColor(
                                            Color(#colorLiteral(
                                                red: 0.9490196078,
                                                green: 0.9725490196,
                                                blue: 0.9921568627,
                                                alpha: 1
                                            ))
                                        )
                                }
                                
                                // Expense
                                Button(action: {
                                    selectedTransaction = nil
                                    showAddTransactionView.toggle()
                                }) {
                                    Image(systemName: "arrow.up.circle")
                                        .font(.system(size: 30))
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
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    Color(#colorLiteral(
                                        red: 0.2980392157,
                                        green: 0.3058823529,
                                        blue: 0.6078431373,
                                        alpha: 0.8026438328
                                    ))
                                )
                                .stroke(Color.gray.opacity(0.3))
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 5)
                        .padding(.bottom, 5)
                        
                        Divider().padding(.horizontal)
                    }
                }
                .background(Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1))) // #F7F7F7 Keep header on white background
                
                // MARK: - Scrollable Transactions in Middle
                ScrollView {
                    VStack(alignment: .leading) {
                        // Title
                        Text("Transactions")
                            .font(.caption)
                            .padding(.top, 5)
                            .padding(.horizontal, 40)
                            .foregroundColor(
                                Color(#colorLiteral(
                                    red: 0.549,
                                    green: 0.596,
                                    blue: 0.655,
                                    alpha: 1
                                ))
                            )
                        
                        // Grouped transactions with disclosure (with expanded state binding)
                        VStack(spacing: 10) {
                            ForEach(groupedTransactions, id: \.group) { group in
                                DisclosureGroup(
                                    isExpanded: Binding(
                                        get: { disclosureExpandedStates[group.group] ?? true },
                                        set: { disclosureExpandedStates[group.group] = $0 }
                                    )
                                ) {
                                    ForEach(group.transactions, id: \.id) { transaction in
                                        HStack {
                                            TransactionRow(
                                                transaction: transaction,
                                                runningBalance: calculateSubBalance(for: transaction),
                                                selectedGrouping: selectedGrouping
                                            )
                                            Spacer()
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedTransaction = transaction
                                            if transaction.type.lowercased() == "income" {
                                                 showAddIncomeView = true
                                            } else if transaction.type.lowercased() == "expense" {
                                                 showAddTransactionView = true
                                            }
                                        }
                                    }
                                } label: {
                                    Text(group.group)
                                        .font(.caption)
                                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1))) // #8C98A7
                                }
                                .padding()
                                .background(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))) // #FFFFFF
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1))) // #F7F7F7
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                
                // MARK: - Footer (Pinned at Bottom)
                VStack(spacing: 0) {
                    Divider().padding(.horizontal)
                    
                    // Opening Balance
                    HStack {
                        Text("Opening Balance:")
                            .font(.footnote)
                            .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1))) // #8C98A7
                        Spacer()
                        Text("$\(account.openingBalance, specifier: "%.2f")")
                            .font(.footnote)
                            .bold()
                            .foregroundColor(
                                Color(#colorLiteral(
                                    red: 0.3294117647,
                                    green: 0.3568627451,
                                    blue: 0.3921568627,
                                    alpha: 1
                                ))
                            )
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                    
                    Divider().padding(.horizontal)
                    
                    // Grouping Buttons (Day, Month only)
                    Divider().padding(.top, 5)
                    
                    HStack {
                        ForEach(["Day", "Month"], id: \.self) { period in
                            Button(action: { selectedGrouping = period }) {
                                Text(period)
                                    .font(.caption)
                                    .foregroundColor(
                                        selectedGrouping == period
                                        ? Color.white
                                        : Color(#colorLiteral(
                                            red: 0.2980392157,
                                            green: 0.3058823529,
                                            blue: 0.6078431373,
                                            alpha: 0.8026438328
                                        ))
                                    )
                                    .padding(5)
                                    .background(
                                        selectedGrouping == period
                                        ? Color(#colorLiteral(
                                            red: 0.2980392157,
                                            green: 0.3058823529,
                                            blue: 0.6078431373,
                                            alpha: 0.8026438328
                                        ))
                                        : Color(#colorLiteral(
                                            red: 0.5490196078,
                                            green: 0.5960784314,
                                            blue: 0.6549019608,
                                            alpha: 1
                                        ))
                                        .opacity(0.1)
                                    )
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.top, 5)
                    .padding(.bottom)
                    .background(Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)))
                }
            }
        }
        // MARK: - onAppear & Sheets
        .onAppear {
            transactionStore.load(for: account.id)
        }
        .sheet(isPresented: $showAddTransactionView) {
            if let transactionToEdit = selectedTransaction {
                // Edit Mode
                AddExpenseTransactionView(
                    ledgerGroup: account.ledgerGroup,
                    existingTransaction: transactionToEdit,
                    onSave: { updatedTransaction in
                        transactionStore.save(updatedTransaction, for: account.id)
                    }
                )
            } else {
                // Add Mode
                AddExpenseTransactionView(
                    ledgerGroup: account.ledgerGroup,
                    existingTransaction: nil,
                    onSave: { newTransaction in
                        transactionStore.save(newTransaction, for: account.id)
                    }
                )
            }
        }
        .sheet(isPresented: $showAddIncomeView) {
            AddIncomeView(
                ledgerGroup: account.ledgerGroup,
                existingTransaction: selectedTransaction
            )
        }
        .sheet(isPresented: $showEditTransactionView) {
            if let transactionToEdit = selectedTransaction {
                EditTransactionView(
                    transaction: transactionToEdit,
                    onSave: { updatedTransaction in
                        transactionStore.save(updatedTransaction, for: account.id)
                    },
                    onDelete: { transactionToDelete in
                        transactionStore.delete(transactionToDelete, for: account.id)
                    }
                )
            }
        }
    }
}
struct AccountTransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountTransactionsView(account: Account(
            id: UUID(),
            name: "Sample Account",
            type: "Debit",
            description: "Preview account for testing",
            openingBalance: 1000.00,
            asOfDate: Date(),
            ledgerGroup: "Sample Ledger"
        ))
    }
}
