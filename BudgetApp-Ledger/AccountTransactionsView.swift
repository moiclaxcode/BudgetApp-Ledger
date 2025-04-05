//
//  AccountTransactionsView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/5/25.
//  3/14/25 V1.0 - Working version
//  Updated with corrected logic for debit/credit expense & income handling including proper transfer handling for credit accounts
//  Updated to show "As of today" balance (using transactions up to today) in header while listing all transactions below.
//

import SwiftUI

struct AccountTransactionsView: View {
    // MARK: - Properties
    var account: Account
    var accountStore: AccountStore
    @StateObject private var transactionStore = TransactionStore()
    @State private var showAddTransactionView = false
    @State private var showAddIncomeView = false
    @State private var showTransferFundsView = false
    @State private var selectedTransaction: Transaction?
    
    // For disclosure groups
    @State private var disclosureExpandedStates: [String: Bool] = [:]
    
    // We only have two grouping modes now: Day and Month
    @State private var selectedGrouping: String = "Month"
    
    init(account: Account, accountStore: AccountStore) {
        self.account = account
        self.accountStore = accountStore
    }
    
    // MARK: - Computed Properties
    
    /// Balance computed using only transactions dated up to today.
    private var balanceAsOfToday: Double {
        let uniqueTransactions = Array(Set(transactionStore.transactions))
        let today = Date()
        let filteredTransactions = uniqueTransactions.filter { $0.date <= today }
        
        let transactionTotal = filteredTransactions.reduce(0.0) { total, transaction in
            switch transaction.type {
            case .expense:
                if account.type.lowercased() == "credit" {
                    return total + abs(transaction.amount)
                } else {
                    return total - abs(transaction.amount)
                }
            case .income:
                if account.type.lowercased() == "credit" {
                    return total - abs(transaction.amount)
                } else {
                    return total + abs(transaction.amount)
                }
            case .transfer:
                if transaction.fromAccountID == account.id {
                    return total - abs(transaction.amount)
                } else if transaction.toAccountID == account.id {
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
        
        return account.openingBalance + transactionTotal
    }
    
    /// The running balance for each transaction is computed over all transactions (including future ones).
    private func calculateSubBalance(for transaction: Transaction) -> Double {
        var balance = account.openingBalance
        let uniqueTransactions = Array(Set(transactionStore.transactions)).sorted { $0.date < $1.date }
        
        for trans in uniqueTransactions {
            switch trans.type {
            case .expense:
                if account.type.lowercased() == "credit" {
                    balance += abs(trans.amount)
                } else {
                    balance -= abs(trans.amount)
                }
            case .income:
                if account.type.lowercased() == "credit" {
                    balance -= abs(trans.amount)
                } else {
                    balance += abs(trans.amount)
                }
            case .transfer:
                if trans.fromAccountID == account.id {
                    balance -= abs(trans.amount)
                } else if trans.toAccountID == account.id {
                    if account.type.lowercased() == "credit" {
                        balance -= abs(trans.amount)
                    } else {
                        balance += abs(trans.amount)
                    }
                }
            }
            
            if trans.id == transaction.id {
                return balance
            }
        }
        
        return balance
    }
    
    /// Groups all transactions (including future ones) by day or month.
    private var groupedTransactions: [(group: String, transactions: [Transaction])] {
        let uniqueTransactions = Array(Set(transactionStore.transactions))
        let sortedTransactions = uniqueTransactions.sorted { $0.date > $1.date }
        
        var groups: [Date: [Transaction]] = [:]
        let calendar = Calendar.current
        
        for transaction in sortedTransactions {
            let date = transaction.date
            var groupDate: Date
            
            switch selectedGrouping {
            case "Day":
                groupDate = calendar.startOfDay(for: date)
            default:
                let components = calendar.dateComponents([.year, .month], from: date)
                groupDate = calendar.date(from: components) ?? date
            }
            
            groups[groupDate, default: []].append(transaction)
        }
        
        let sortedKeys = groups.keys.sorted(by: >)
        
        return sortedKeys.map { key -> (group: String, transactions: [Transaction]) in
            let dateFormatter = DateFormatter()
            switch selectedGrouping {
            case "Day":
                dateFormatter.dateFormat = "EEE, MMM d"
            default:
                dateFormatter.dateFormat = "MMM"
            }
            let groupString = dateFormatter.string(from: key)
            return (group: groupString, transactions: groups[key] ?? [])
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)) // #FFFFFF
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // MARK: - Header (Pinned at Top)
                VStack(spacing: 0) {
                    VStack {
                        Text(account.name)
                            .font(.headline)
                            .bold()
                            .foregroundColor(
                                Color(#colorLiteral(red: 0.3294117647, green: 0.3568627451, blue: 0.3921568627, alpha: 1))
                            )
                        Divider()
                        Text(account.ledgerGroup)
                            .font(.caption)
                            .foregroundColor(
                                Color(#colorLiteral(red: 0.3294117647, green: 0.3568627451, blue: 0.3921568627, alpha: 1))
                            )
                        Divider().padding(.horizontal)
                    }
                    .padding(.top, 5)
                    
                    VStack {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Balance")
                                    .font(.caption)
                                    .foregroundColor(
                                        Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1))
                                    )
                                Text("$\(balanceAsOfToday, specifier: "%.2f")")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(
                                        Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1))
                                    )
                                Text("As of today")
                                    .font(.caption2)
                                    .foregroundColor(
                                        Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1))
                                    )
                            }
                            Spacer()
                            
                            HStack {
                                Button(action: {
                                    selectedTransaction = nil
                                    showAddIncomeView.toggle()
                                }) {
                                    Image(systemName: "arrow.down.circle")
                                        .imageScale(.large)
                                        .foregroundColor(
                                            Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1))
                                        )
                                }
                                
                                Button(action: {
                                    selectedTransaction = nil
                                    showAddTransactionView.toggle()
                                }) {
                                    Image(systemName: "arrow.up.circle")
                                        .imageScale(.large)
                                        .foregroundColor(
                                            Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1))
                                        )
                                }
                            }
                        }
                        .padding()
                        .padding(.horizontal, 20)
                        .background(RoundedRectangle(cornerRadius: 5)
                                .fill(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.8025662252))) //#012169 80% opacity header background
                            .shadow(color: Color.gray.opacity(0.3), radius: 2, y: 1)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 5)
                        .padding(.bottom, 5)
                        
                        Divider().padding(.horizontal)
                    }
                }
                .background(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))) // #FFFFFF
                
                // MARK: - Scrollable Transactions in Middle
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("Transactions")
                            .font(.caption)
                            .padding(.top, 5)
                            .padding(.bottom, 10)
                            .padding(.horizontal, 40)
                            .foregroundColor(
                                Color(#colorLiteral(red: 0.549, green: 0.596, blue: 0.655, alpha: 1))
                            )
                        // MARK: - New Plain List Style Setup
                        VStack(spacing: 0) {
                            ForEach(groupedTransactions, id: \.group) { group in
                                VStack(spacing: 0) {
                                    // Group label
                                    HStack {
                                        Text(group.group)
                                            .font(.caption)
                                            .foregroundColor(Color.gray)
                                        Spacer()
                                    }
                                    .padding(.top, 4)
                                    .padding(.horizontal, 20)

                                    Divider()
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 5)
                                    
                                    VStack(spacing: 0) {
                                        ForEach(group.transactions, id: \.id) { transaction in
                                            VStack(spacing: 0) {
                                                HStack {
                                                    TransactionRow(
                                                        transaction: transaction,
                                                        runningBalance: calculateSubBalance(for: transaction),
                                                        selectedGrouping: selectedGrouping
                                                    )
                                                    Menu {
                                                        Button("Edit") {
                                                            selectedTransaction = transaction
                                                            switch transaction.type {
                                                            case .income: showAddIncomeView = true
                                                            case .expense: showAddTransactionView = true
                                                            case .transfer: showTransferFundsView = true
                                                            }
                                                        }
                                                        Button("Delete", role: .destructive) {
                                                            transactionStore.delete(transaction, for: account.id)
                                                        }
                                                    } label: {
                                                        Image(systemName: "ellipsis")
                                                            .rotationEffect(.degrees(90))
                                                            .foregroundColor(.gray)
                                                    }
                                                }
                                                Divider()
                                                    .padding(.horizontal, 20)
                                                    .padding(.bottom, 10)
                                            }
                                        }
                                    }
                                    .background(Color.white) //Rows Background
                                    .cornerRadius(5)
                                    .shadow(color: Color.gray.opacity(0.3), radius: 2, y: 1)
                                    .padding(.horizontal, 10)
                                    .padding(.bottom, 5)
                                }
                            }
                        }
                        
                        .padding(.bottom,10)
                        .background(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))) //#FFFFFF Behind row background
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                    }
                }
                
                // MARK: - Footer (Pinned at Bottom)
                VStack(spacing: 0) {
                    Divider().padding(.horizontal)
                    
                    HStack {
                        Text("Opening Balance:")
                            .font(.footnote)
                            .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                        Spacer()
                        Text("$\(account.openingBalance, specifier: "%.2f")")
                            .font(.footnote)
                            .bold()
                            .foregroundColor(Color(#colorLiteral(red: 0.2470588235, green: 0.2901960784, blue: 0.3490196078, alpha: 1)))
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                    
                    Divider().padding(.horizontal)
                    
                    Divider().padding(.top, 5)
                    
                    HStack {
                        ForEach(["Day", "Month"], id: \.self) { period in
                            Button(action: { selectedGrouping = period }) {
                                Text(period)
                                    .font(.caption2)
                                    .foregroundColor(
                                        selectedGrouping == period
                                        ? Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1))
                                        : Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.8025662252)) //#012169 80% opacity
                                    )
                                    .padding(5)
                                    .background(
                                        selectedGrouping == period
                                        ? Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.8025662252)) //#012169 80% opacity
                                        : Color.white
                                    )
                                    .cornerRadius(5)
                            }
                        }
                    }
                    .frame(width: 120)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 3)
                    .background(Color.white)
                    .cornerRadius(5)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)
                }
            }
        }
        // MARK: - onAppear, onReceive
        .onAppear {
            transactionStore.load(for: account.id)
        }
        .onReceive(NotificationCenter.default.publisher(for: .transactionsUpdated)) { _ in
            transactionStore.load(for: account.id)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            transactionStore.load(for: account.id)
        }
        
        //MARK: - Sheets for AddTransaction, AddExpense, AddIncome and TransferFundsView
        .sheet(isPresented: $showAddTransactionView) {
            if let transactionToEdit = selectedTransaction {
                AddExpenseTransactionView(
                    ledgerGroup: account.ledgerGroup,
                    existingTransaction: transactionToEdit,
                    onSave: { updatedTransaction in
                        transactionStore.save(updatedTransaction, for: account.id)
                    }
                )
            } else {
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
        .sheet(isPresented: $showTransferFundsView) {
            if let transactionToEdit = selectedTransaction {
                TransferFundsView(
                    accountStore: accountStore,
                    existingTransaction: transactionToEdit,
                    onSave: { updatedTransaction in
                        transactionStore.save(updatedTransaction, for: account.id)
                    }
                )
            }
        }
    }
}
    //MARK: - Preview Provider section
struct AccountTransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountTransactionsView(
            account: Account(
                id: UUID(),
                name: "Sample Account",
                type: "Debit",
                description: "Preview account for testing",
                openingBalance: 1000.00,
                asOfDate: Date(),
                ledgerGroup: "Sample Ledger"
            ),
            accountStore: AccountStore()
        )
    }
}
