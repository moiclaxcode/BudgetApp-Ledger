//
//  IncomeView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/17/25.
//  Refactored on 3/24/25 to match ExpenseTransactionView refinements.
//

import SwiftUI

struct IncomeView: View {
    // MARK: - Properties
    var ledgerGroup: String
    
    // Filtered transactions
    @State private var incomeTransactions: [Transaction] = []
    
    // Controls for Add/Edit
    @State private var showAddIncomeTransactionView = false
    @State private var showEditIncomeView = false
    @State private var selectedTransaction: Transaction?
    
    // Grouping
    @State private var selectedGrouping: String = "Month" // Default to 'Month' or 'Day'
    
    // Current month for filtering
    @State private var currentMonth: Date = Date()
    
    // Disclosure group expansions
    @State private var disclosureExpandedStates: [String: Bool] = [:]
    
    // Delete confirmation
    @State private var showDeleteConfirmation = false
    @State private var transactionToDelete: Transaction?
    
    // MARK: - Computed: Total Income
    private var totalIncome: Double {
        incomeTransactions.map { abs($0.amount) }.reduce(0, +)
    }
    
    // MARK: - Filtered, Grouped Transactions
    private var groupedTransactions: [(group: String, transactions: [Transaction])] {
        // Sort descending by date
        let sorted = incomeTransactions.sorted { $0.date > $1.date }
        let calendar = Calendar.current
        var groups: [Date: [Transaction]] = [:]
        
        for transaction in sorted {
            // Group by Day or Month
            let groupDate: Date
            if selectedGrouping == "Day" {
                groupDate = calendar.startOfDay(for: transaction.date)
            } else {
                // "Month"
                let comps = calendar.dateComponents([.year, .month], from: transaction.date)
                groupDate = calendar.date(from: comps) ?? transaction.date
            }
            groups[groupDate, default: []].append(transaction)
        }
        
        // Sort group keys descending
        let sortedKeys = groups.keys.sorted(by: >)
        
        // Convert each key to a display string
        return sortedKeys.map { key -> (group: String, transactions: [Transaction]) in
            let formatter = DateFormatter()
            if selectedGrouping == "Day" {
                formatter.dateFormat = "EEE, MMM d" // e.g. "Sat, Mar 22"
            } else {
                formatter.dateFormat = "MMM"        // e.g. "Mar"
            }
            let groupString = formatter.string(from: key)
            return (group: groupString, transactions: groups[key] ?? [])
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
                    .edgesIgnoringSafeArea(.all)
                
                // Main vertical stack
                mainContent
                
                // Floating Add button
                floatingAddButton
            }
            .navigationBarHidden(true)
            .onAppear {
                loadTransactions()
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionUpdated)) { _ in
                loadTransactions()
            }
            // Sheets
            .sheet(isPresented: $showAddIncomeTransactionView, onDismiss: {
                loadTransactions()
            }) {
                AddIncomeView(
                    ledgerGroup: ledgerGroup,
                    existingTransaction: nil
                )
            }
            .sheet(isPresented: $showEditIncomeView) {
                if let transactionToEdit = selectedTransaction {
                    AddIncomeView(
                        ledgerGroup: ledgerGroup,
                        existingTransaction: transactionToEdit
                    )
                }
            }
            // Delete Confirmation
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Income?"),
                    message: Text("Are you sure you want to delete this income? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        if let transaction = transactionToDelete {
                            deleteTransaction(transaction)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    // MARK: - Main Content (Split out of body)
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
                .frame(height: 0.5)
                .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                .padding(.horizontal)
            
            transactionsSection
            
            Divider()
                .frame(height: 0.5)
                .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                .padding(.horizontal)
            
            footerView
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 5) {
            Divider().frame(width: 100, height: 0.5)
                .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                .padding(.top, 10)
            
            Text("$\(totalIncome, specifier: "%.2f")")
                .font(.headline)
                .bold()
                .foregroundColor(Color(#colorLiteral(red: 0.1568627451, green: 0.5019607843, blue: 0.1843137255, alpha: 1)))
            
            Divider().frame(width: 100, height: 0.5)
                .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% opacity
            
            // Month-Year header with left/right arrows
            HStack {
                Button(action: {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    loadTransactions()
                }) {
                    Image(systemName: "chevron.left.circle")
                        .imageScale(.medium)
                        .foregroundColor(
                            Color(#colorLiteral(red: 0.5490196078,
                                                green: 0.5960784314,
                                                blue: 0.6549019608,
                                                alpha: 1))
                        )
                }
                Spacer()
                Text(formattedMonth(currentMonth))
                    .font(.caption)
                    .foregroundColor(
                        Color(#colorLiteral(red: 0.3294117647,
                                            green: 0.3568627451,
                                            blue: 0.3921568627,
                                            alpha: 1))
                    )
                Spacer()
                Button(action: {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    loadTransactions()
                }) {
                    Image(systemName: "chevron.right.circle")
                        .imageScale(.medium)
                        .foregroundColor(
                            Color(#colorLiteral(red: 0.5490196078,
                                                green: 0.5960784314,
                                                blue: 0.6549019608,
                                                alpha: 1))
                        )
                }
            }
            .padding(5)
            .padding(.horizontal, 120)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Transactions Section
    private var transactionsSection: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Income")
                    .font(.caption)
                    .padding(.horizontal, 40)
                    .padding(.top, 5)
                    .foregroundColor(
                        Color(#colorLiteral(red: 0.1568627451, green: 0.5019607843, blue: 0.1843137255, alpha: 1))
                    )
                
                VStack(spacing: 10) {
                    ForEach(groupedTransactions, id: \.group) { group in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { disclosureExpandedStates[group.group] ?? true },
                                set: { disclosureExpandedStates[group.group] = $0 }
                            )
                        ) {
                            ForEach(group.transactions, id: \.id) { transaction in
                                // Single row
                                VStack(spacing: 0){
                                    HStack {
                                        transactionRow(transaction)
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedTransaction = transaction
                                        showEditIncomeView = true
                                    }
                                    Divider()
                                        .frame(height: 0.1)
                                }
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.group)
                                    .font(.caption2)
                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                        Divider()
                                    .frame(width: 70, height: 0.40)
                                    .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                                    .padding(.bottom, 5)
                            }
                        }
                        .padding(8)
                        .padding(.horizontal, 10)
                        .background(Color.white) // Background for row list
                        .cornerRadius(5)
                        .shadow(color: Color.gray.opacity(0.3), radius: 2, y: 1)
                    }
                }
                .padding(.bottom, 10)
                .background(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))) // #F7F7F7 Background behind list
                .cornerRadius(8)
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Footer View
    private var footerView: some View {
        HStack {
            ForEach(["Day", "Month"], id: \.self) { period in
                Button(action: { selectedGrouping = period }) {
                    Text(period)
                        .font(.caption2)
                        .foregroundColor(
                            selectedGrouping == period
                            ? Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1)) // fontColor (Selected)
                            : Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995)) // fontColor (Unselected) #012169 80% Opacity
                        )
                        .padding(5)
                        .background(
                            selectedGrouping == period
                            ? Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.8013503725)) // Background (Selected) #012169 80% Opacity
                            : Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1)) // Background (Unselected)
                        )
                        .cornerRadius(5)
                }
            }
        }
        .frame(width: 90)
        .padding(.vertical, 3)
        .padding(.horizontal, 3)
        .background(Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1))) // background behind day and month
        .cornerRadius(5)
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
    }
    
    // MARK: - Floating Add Button
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showAddIncomeTransactionView = true }) {
                    Image(systemName: "plus.circle")
                        .imageScale(.large)
                        .foregroundColor(
                            Color(#colorLiteral(red: 0.1568627451, green: 0.5019607843, blue: 0.1843137255, alpha: 1))
                        )
                }
                .padding(.vertical, 60)
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Transaction Row
    private func transactionRow(_ transaction: Transaction) -> some View {
        HStack(spacing: 5) {
            VStack(alignment: .leading, spacing: 2) {
                // Top line: description + payee
                HStack {
                    Text(transaction.description.isEmpty ? "No Description" : transaction.description)
                        .font(.caption)
                        .foregroundColor(Color(#colorLiteral(red: 0.3294117647, green: 0.3568627451, blue: 0.3921568627, alpha: 1)))
                    if let payee = transaction.payee, !payee.isEmpty {
                        Text(" - \(payee)")
                            .font(.caption2)
                            .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                    }
                }
                // Second line: date + account name
                HStack {
                    Text(shortDateFormatted(transaction.date))
                        .font(.caption2)
                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                    if let account = UserDefaults.standard.getAccount(for: transaction.accountID) {
                        Text(account.name)
                            .font(.caption2)
                            .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                    }
                }
            }
            Spacer()
            // Amount
            Text("$\(abs(transaction.amount), specifier: "%.2f")")
                .font(.caption)
                .foregroundColor(Color(#colorLiteral(red: 0.1568627451, green: 0.5019607843, blue: 0.1843137255, alpha: 1)))
        }
        .padding(.vertical, 1)
    }
    
    // MARK: - Load Transactions
    private func loadTransactions() {
        // Combine account transactions + all income transactions, then filter
        let accountTx = UserDefaults.standard.getAllAccountTransactions()
        let ledgerTx = UserDefaults.standard.getIncomeTransactions().filter {
            $0.ledgerGroup == ledgerGroup
        }
        
        let merged = Array(Set(accountTx + ledgerTx))
        
        let calendar = Calendar.current
        let selectedMonth = calendar.component(.month, from: currentMonth)
        let selectedYear = calendar.component(.year, from: currentMonth)
        
        incomeTransactions = merged.filter { transaction in
            let transactionMonth = calendar.component(.month, from: transaction.date)
            let transactionYear = calendar.component(.year, from: transaction.date)
            return transaction.type == .income &&
                   transaction.ledgerGroup == ledgerGroup &&
                   transactionMonth == selectedMonth &&
                   transactionYear == selectedYear
        }
    }
    
    // MARK: - Formatted Month
    private func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    // MARK: - Short Date
    private func shortDateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    // MARK: - Confirm Delete
    private func confirmDeleteTransaction(_ transaction: Transaction) {
        transactionToDelete = transaction
        showDeleteConfirmation = true
    }
    
    // MARK: - Delete
    private func deleteTransaction(_ transaction: Transaction) {
        incomeTransactions.removeAll { $0.id == transaction.id }
        UserDefaults.standard.saveIncomeTransactions(incomeTransactions)
        loadTransactions()
    }
}

// MARK: - Preview
struct IncomeView_Previews: PreviewProvider {
    static var previews: some View {
        IncomeView(ledgerGroup: "Sample Ledger")
    }
}
