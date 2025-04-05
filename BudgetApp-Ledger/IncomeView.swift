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

    @State private var incomeTransactions: [Transaction] = []
    @State private var showAddIncomeTransactionView = false
    @State private var showEditIncomeView = false
    @State private var selectedTransaction: Transaction?
    @State private var selectedGrouping: String = "Month"
    @State private var currentMonth: Date = Date()
    @State private var showDeleteConfirmation = false
    @State private var transactionToDelete: Transaction?

    // MARK: - Computed: Total Income
    private var totalIncome: Double {
        incomeTransactions.map { abs($0.amount) }.reduce(0, +)
    }

    // MARK: - Computed: Grouped Transactions by Day/Month
    private var groupedTransactions: [(group: String, transactions: [Transaction])] {
        let sorted = incomeTransactions.sorted { $0.date > $1.date }
        let calendar = Calendar.current
        var groups: [Date: [Transaction]] = [:]

        for transaction in sorted {
            let groupDate: Date
            if selectedGrouping == "Day" {
                groupDate = calendar.startOfDay(for: transaction.date)
            } else {
                let comps = calendar.dateComponents([.year, .month], from: transaction.date)
                groupDate = calendar.date(from: comps) ?? transaction.date
            }
            groups[groupDate, default: []].append(transaction)
        }

        let sortedKeys = groups.keys.sorted(by: >)
        return sortedKeys.map { key in
            let formatter = DateFormatter()
            formatter.dateFormat = selectedGrouping == "Day" ? "EEE, MMM d" : "MMM"
            return (formatter.string(from: key), groups[key] ?? [])
        }
    }

    // MARK: - View Body
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)

                
                VStack(spacing: 0) {
                    // MARK: - Header Section
                    VStack(spacing: 5) {
                        Divider().frame(width: 100, height: 0.5)
                            .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995)))
                            .padding(.top, 10)

                        Text("$\(totalIncome, specifier: "%.2f")")
                            .font(.headline)
                            .bold()
                            .foregroundColor(Color(#colorLiteral(red: 0.1568627451, green: 0.5019607843, blue: 0.1843137255, alpha: 1)))

                        Divider().frame(width: 100, height: 0.5)
                            .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995)))

                        HStack {
                            Button(action: {
                                currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                                loadTransactions()
                            }) {
                                Image(systemName: "chevron.left.circle")
                                    .imageScale(.medium)
                                    .foregroundColor(Color.gray)
                            }
                            Spacer()
                            Text(formattedMonth(currentMonth))
                                .font(.caption)
                                .foregroundColor(Color.gray)
                            Spacer()
                            Button(action: {
                                currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                                loadTransactions()
                            }) {
                                Image(systemName: "chevron.right.circle")
                                    .imageScale(.medium)
                                    .foregroundColor(Color.gray)
                            }
                        }
                        .padding(.horizontal, 120)
                    }
                    .padding(.vertical, 10)

                    Divider()
                        .frame(height: 0.5)
                        .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995)))
                        .padding(.horizontal)

                    // MARK: - Scrollable Transactions in Middle
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text("Income")
                                .font(.caption)
                                .padding(.horizontal, 40)
                                .padding(.top, 5)
                                .foregroundColor(Color(#colorLiteral(red: 0.1568627451, green: 0.5019607843, blue: 0.1843137255, alpha: 1))) // #28802F

                            // MARK: - New Plain List Style Setup
                            ForEach(groupedTransactions, id: \.group) { group in
                                VStack(spacing: 0) {
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
                                                    transactionRow(transaction)
                                                    Menu {
                                                        Button("Edit") {
                                                            selectedTransaction = transaction
                                                            showEditIncomeView = true
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
                    
                    // MARK: - Footer Buttons (Day/Month)
                    Divider()
                        .frame(height: 0.5)
                        .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995)))
                        .padding(.horizontal)

                    
                    HStack {
                        ForEach(["Day", "Month"], id: \.self) { period in
                            Button(action: { selectedGrouping = period }) {
                                Text(period)
                                    .font(.caption2)
                                    .foregroundColor(
                                        selectedGrouping == period
                                        ? Color.white
                                        : Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))
                                    )
                                    .padding(5)
                                    .background(
                                        selectedGrouping == period
                                        ? Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.8013503725))
                                        : Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1))
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

                // MARK: - Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showAddIncomeTransactionView = true }) {
                            Image(systemName: "plus.circle")
                                .imageScale(.large)
                                .foregroundColor(Color(#colorLiteral(red: 0.1568627451, green: 0.5019607843, blue: 0.1843137255, alpha: 1)))
                        }
                        .padding(.vertical, 15)
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { loadTransactions() }
            .onReceive(NotificationCenter.default.publisher(for: .transactionUpdated)) { _ in loadTransactions() }

            // MARK: - Sheets
            .sheet(isPresented: $showAddIncomeTransactionView, onDismiss: loadTransactions) {
                AddIncomeView(ledgerGroup: ledgerGroup, existingTransaction: nil)
            }
            .sheet(isPresented: $showEditIncomeView) {
                if let transaction = selectedTransaction {
                    AddIncomeView(ledgerGroup: ledgerGroup, existingTransaction: transaction)
                }
            }

            // MARK: - Delete Confirmation Alert
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Income?"),
                    message: Text("Are you sure you want to delete this income?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let tx = transactionToDelete {
                            deleteTransaction(tx)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }

    // MARK: - Transaction Row
    private func transactionRow(_ transaction: Transaction) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(transaction.description.isEmpty ? "No Description" : transaction.description)
                        .font(.caption)
                        .foregroundColor(Color(#colorLiteral(red: 0.3294117647, green: 0.3568627451, blue: 0.3921568627, alpha: 1)))
                    if let payee = transaction.payee, !payee.isEmpty {
                        Text(" - \(payee)")
                            .font(.caption2)
                            .foregroundColor(Color.gray)
                    }
                }
                HStack {
                    Text(shortDateFormatted(transaction.date))
                        .font(.caption2)
                        .foregroundColor(Color.gray)
                    if let account = UserDefaults.standard.getAccount(for: transaction.accountID) {
                        Text(account.name)
                            .font(.caption2)
                            .foregroundColor(Color.gray)
                    }
                }
            }
            Spacer()
            Text("$\(abs(transaction.amount), specifier: "%.2f")")
                .font(.caption)
                .foregroundColor(Color(#colorLiteral(red: 0.1568627451, green: 0.5019607843, blue: 0.1843137255, alpha: 1)))
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 20)
    }

    // MARK: - Load & Filter Transactions
    private func loadTransactions() {
        let accountTx = UserDefaults.standard.getAllAccountTransactions()
        let ledgerTx = UserDefaults.standard.getIncomeTransactions().filter {
            $0.ledgerGroup == ledgerGroup
        }

        let merged = Array(Set(accountTx + ledgerTx))
        let calendar = Calendar.current
        let selectedMonth = calendar.component(.month, from: currentMonth)
        let selectedYear = calendar.component(.year, from: currentMonth)

        incomeTransactions = merged.filter {
            let txMonth = calendar.component(.month, from: $0.date)
            let txYear = calendar.component(.year, from: $0.date)
            return $0.type == .income &&
                   $0.ledgerGroup == ledgerGroup &&
                   txMonth == selectedMonth &&
                   txYear == selectedYear
        }
    }

    // MARK: - Utility Formatters
    private func formattedMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func shortDateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    // MARK: - Delete Logic
    private func confirmDeleteTransaction(_ transaction: Transaction) {
        transactionToDelete = transaction
        showDeleteConfirmation = true
    }

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
