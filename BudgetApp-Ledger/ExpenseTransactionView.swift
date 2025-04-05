//
//  ExpenseTransactionView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/7/25.
//  3/14/25 V1.1 - Refactored to use shared TransactionRow and ZStack layout
//

import SwiftUI

struct ExpenseTransactionView: View {
    var ledgerGroup: String
    @State private var transactions: [Transaction] = [] // Loaded transactions
    @State private var showAddExpenseTransactionView = false
    @State private var selectedGrouping: String = "Month" // Default grouping now "Month"
    @State private var selectedTransaction: Transaction? // For editing
    @State private var showEditExpenseView = false
    @State private var currentMonth: Date = Date() // For filtering by month
    @State private var showDeleteConfirmation = false
    @State private var transactionToDelete: Transaction?
    
    // New state dictionary to manage expanded states for each disclosure group
    @State private var disclosureExpandedStates: [String: Bool] = [:]
    
    // Total expenses computed property
    private var totalExpenses: Double {
        transactions.map { abs($0.amount) }.reduce(0, +)
    }
    
    // Load transactions from both accounts and ledger based on current month and expense type
    private func loadTransactions() {
        let accountTransactions = UserDefaults.standard.getAllAccountTransactions() // Returns all account transactions (not filtered)
        let ledgerTransactions = UserDefaults.standard.getTransactions(for: ledgerGroup)
        let allTransactions = Array(Set(accountTransactions + ledgerTransactions))
        let calendar = Calendar.current
        let selectedMonth = calendar.component(.month, from: currentMonth)
        let selectedYear = calendar.component(.year, from: currentMonth)
        
        transactions = allTransactions.filter { transaction in
            let transactionMonth = calendar.component(.month, from: transaction.date)
            let transactionYear = calendar.component(.year, from: transaction.date)
            return transaction.type == .expense &&
                   transaction.ledgerGroup.lowercased() == ledgerGroup.lowercased() &&  // Filter by ledger group
                   transactionMonth == selectedMonth &&
                   transactionYear == selectedYear
        }
    }
    
    // Group transactions by Day or Month in descending order
    private var groupedTransactions: [(group: String, transactions: [Transaction])] {
        let uniqueTransactions = Array(Set(transactions))
        let sortedTransactions = uniqueTransactions.sorted { $0.date > $1.date } // Descending order
        var groups: [Date: [Transaction]] = [:]
        let calendar = Calendar.current
        
        for transaction in sortedTransactions {
            let groupDate: Date
            if selectedGrouping == "Day" {
                groupDate = calendar.startOfDay(for: transaction.date)
            } else { // "Month"
                let components = calendar.dateComponents([.year, .month], from: transaction.date)
                groupDate = calendar.date(from: components) ?? transaction.date
            }
            groups[groupDate, default: []].append(transaction)
        }
        
        // Sort the group keys descending
        let sortedKeys = groups.keys.sorted(by: >)
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
    
    // Format the current month for the header (e.g. "March 2025")
    private func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    // Helper to format transaction date for row display (e.g. "MM/dd/yy")
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: date)
    }
    
    // Function to move transactions (if drag-and-drop ordering is desired)
    private func moveTransaction(from source: IndexSet, to destination: Int) {
        transactions.move(fromOffsets: source, toOffset: destination)
        UserDefaults.standard.saveExpenseTransactions(transactions)
    }
    
    // Confirm deletion
    private func confirmDeleteTransaction(_ transaction: Transaction) {
        transactionToDelete = transaction
        showDeleteConfirmation = true
    }
    
    // Delete a transaction and refresh the list
    private func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        UserDefaults.standard.saveExpenseTransactions(transactions)
        loadTransactions()
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // MARK: - Header Section
                    VStack(spacing: 5) {
                        totalExpensesSection
                        
                        // Month-Year header with left/right arrows
                        HStack {
                            Button(action: {
                                currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                                loadTransactions()
                            }) {
                                Image(systemName: "chevron.left.circle")
                                    .imageScale(.medium)
                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                            }
                            Spacer()
                            Text(formattedMonth(currentMonth))
                                .font(.caption)
                                .foregroundColor(Color(#colorLiteral(red: 0.3294117647, green: 0.3568627451, blue: 0.3921568627, alpha: 1)))
                            Spacer()
                            Button(action: {
                                currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                                loadTransactions()
                            }) {
                                Image(systemName: "chevron.right.circle")
                                    .imageScale(.medium)
                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                            }
                        }
                        .padding(.horizontal, 120)
                    }
                    .padding(.vertical, 10)
                    
                    Divider()
                        .frame(height: 0.5)
                        .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                        .padding(.horizontal)
                    
                    // MARK: - Scrollable Transactions in Middle
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text("Expenses")
                                .font(.caption)
                                .padding(.horizontal, 40)
                                .padding(.top, 5)
                                .foregroundColor(Color(#colorLiteral(red: 0.8901960784, green: 0.09411764706, blue: 0.2156862745, alpha: 1))) // #E31837
                        
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
                                                            runningBalance: nil,
                                                            selectedGrouping: selectedGrouping,
                                                            showPayFrom: true
                                                        )
                                                        Menu {
                                                            Button("Edit") {
                                                                selectedTransaction = transaction
                                                                showEditExpenseView = true
                                                            }
                                                            Button("Delete", role: .destructive) {
                                                                confirmDeleteTransaction(transaction)
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
                            .padding(.bottom, 10)
                            .background(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))) // #F7F7F7 Background behind list
                            .cornerRadius(8)
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // MARK: - Footer
                    Divider()
                        .frame(height: 0.5)
                        .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                        .padding(.horizontal)
                   
                    
                    // Footer: Grouping Buttons (only "Day" and "Month")
                    groupingButtons
                }
                
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showAddExpenseTransactionView = true }) {
                            Image(systemName: "plus.circle")
                                .imageScale(.large)
                                .foregroundColor(Color(#colorLiteral(red: 0.8901960784, green: 0.09411764706, blue: 0.2156862745, alpha: 1))) // #E31837
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { loadTransactions() }
            .onReceive(NotificationCenter.default.publisher(for: .transactionUpdated)) { _ in
                loadTransactions()
            }
            // MARK: - .Sheets
            
            .sheet(isPresented: $showAddExpenseTransactionView, onDismiss: { loadTransactions() }) {
                AddExpenseTransactionView(ledgerGroup: ledgerGroup, onSave: { transaction in
                     // Persist to ledger transactions
                     var ledgerTransactions = UserDefaults.standard.getTransactions(for: ledgerGroup)
                     ledgerTransactions.append(transaction)
                     UserDefaults.standard.saveExpenseTransactions(ledgerTransactions)
                     
                     // Persist to account transactions
                     var accountTransactions = UserDefaults.standard.getAllAccountTransactions()
                     accountTransactions.append(transaction)
                     UserDefaults.standard.saveTransactions(accountTransactions)
                     
                     loadTransactions()
                })
            }
            .sheet(isPresented: $showEditExpenseView) {
                if let transactionToEdit = selectedTransaction {
                     AddExpenseTransactionView(
                         ledgerGroup: ledgerGroup,
                         existingTransaction: transactionToEdit,
                         onSave: { transaction in
                             // Update ledger transactions
                             var ledgerTransactions = UserDefaults.standard.getTransactions(for: ledgerGroup)
                             if let index = ledgerTransactions.firstIndex(where: { $0.id == transaction.id }) {
                                 ledgerTransactions[index] = transaction
                             } else {
                                 ledgerTransactions.append(transaction)
                             }
                             UserDefaults.standard.saveExpenseTransactions(ledgerTransactions)
                             
                             // Update account transactions
                             var accountTransactions = UserDefaults.standard.getAllAccountTransactions()
                             if let index = accountTransactions.firstIndex(where: { $0.id == transaction.id }) {
                                 accountTransactions[index] = transaction
                             } else {
                                 accountTransactions.append(transaction)
                             }
                             UserDefaults.standard.saveTransactions(accountTransactions)
                             
                             loadTransactions()
                         }
                     )
                }
            }
            // MARK: - Delete
            
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Expense?"),
                    message: Text("Are you sure you want to delete this expense? This action cannot be undone."),
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
    
    // MARK: - Subviews
    
    private var totalExpensesSection: some View {
        VStack(spacing: 5) {
            Divider().frame(width: 100, height: 0.5)
                .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
            Text("$\(totalExpenses, specifier: "%.2f")")
                .font(.headline)
                .foregroundColor(Color(#colorLiteral(red: 0.8901960784, green: 0.09411764706, blue: 0.2156862745, alpha: 1))) // #E31837
            Divider().frame(width: 100, height: 0.5)
                .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
        }
        .padding(5)
    }
    
    private var groupingButtons: some View {
        HStack {
            ForEach(["Day", "Month"], id: \.self) { period in
                Button(action: { selectedGrouping = period }) {
                    Text(period)
                        .font(.caption2)
                        .foregroundColor(
                            selectedGrouping == period
                            ? Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1)) // fontColor (#f2f8fd) for day and month (Selected)
                            : Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995)) // fontColor for day and month (Unselected) #012169
                        )
                        .padding(5)
                        .background(
                            selectedGrouping == period
                            ? Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.8012727649)) // Background for day and month (Selected) #012169
                            : Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1)) // Background for day and month (Unselected)
                        )
                        .cornerRadius(5)
                        
                }
            }
        }
        .frame(width:120)
        .padding(.vertical, 3)
        .padding(.horizontal, 3)
        .background(Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1))) // background behind day and month
        .cornerRadius(5)
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
    }
}

struct ExpenseTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseTransactionView(ledgerGroup: "Sample Ledger")
    }
}
