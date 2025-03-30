//
//  StatsRow.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/3/25.
//  3/11/25 V1.0 - Working version

import SwiftUI

struct StatsRow: View {
    var ledgerGroup: String
    @State private var stats: [(month: String, income: Double, expenses: Double, balance: Double)] = []

    private func calculateStats() {
        let allTransactions = CategoryStorage.getTransactions()
        let groupedByMonth = Dictionary(grouping: allTransactions) { transaction in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM yyyy"
            return formatter.string(from: transaction.date)
        }

        let sortedMonths = groupedByMonth.keys.sorted().suffix(3)

        stats = sortedMonths.map { month in
            let transactions = groupedByMonth[month] ?? []
            let income = transactions.filter { $0.type == "Income" }.reduce(0) { $0 + $1.amount }
            let expenses = transactions.filter { $0.type == "Expense" }.reduce(0) { $0 + $1.amount }
            let balance = income - expenses
            return (month, income, expenses, balance)
        }
    }

    var body: some View {
        VStack {
            ForEach(stats, id: \.month) { stat in
                HStack {
                    Spacer()
                    Text(stat.month).frame(width: 80)
                    Text(String(format: "%.2f", stat.income)).frame(width: 80)
                    Text(String(format: "%.2f", stat.expenses)).frame(width: 80)
                    Text(String(format: "%.2f", stat.balance)).frame(width: 80)
                    Spacer()
                }
                .font(.subheadline)
            }
        }
        .onAppear {
            calculateStats()
        }
    }
}
