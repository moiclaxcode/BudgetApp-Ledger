//
//  TransactionRow.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/6/25.
//  3/14/25 V1.1 - Updated to support payee and pay from display for expenses
//

import SwiftUI

struct TransactionRow: View {
    var transaction: Transaction
    var runningBalance: Double? = nil
    var selectedGrouping: String
    var showPayFrom: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                // Top line: For expense transactions, show subcategory and payee; for income, show description
                if transaction.type.lowercased() == "expense" {
                    let categoryText = transaction.subCategory ?? transaction.parentCategory
                    let payeeText = (transaction.payee?.isEmpty == false) ? " - \(transaction.payee!)" : ""
                    Text("\(categoryText)\(payeeText)")
                        .font(.caption)
                        .foregroundColor(Color(#colorLiteral(
                            red: 0.3294117647,
                            green: 0.3568627451,
                            blue: 0.3921568627,
                            alpha: 1
                        )))
                } else {
                    Text(transaction.description.isEmpty ? "No Description" : transaction.description)
                        .font(.caption)
                        .foregroundColor(Color(#colorLiteral(
                            red: 0.3294117647,
                            green: 0.3568627451,
                            blue: 0.3921568627,
                            alpha: 1
                        )))
                }
                
                // Second line: For expense rows, if showPayFrom is true, display date + account
                // Otherwise, if grouping is Month, show short date
                if showPayFrom, let account = UserDefaults.standard.getAccount(for: transaction.accountID) {
                    HStack {
                        Text(shortDateFormatted(transaction.date))
                        Text(account.name)
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                } else if selectedGrouping == "Month" {
                    Text(shortDateFormatted(transaction.date))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                // THIRD line (the "Upcoming"/"Paid" logic):
                Text(transaction.date > Date() ? "Upcoming" : "Paid")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Amount + optional running balance
            VStack(alignment: .trailing) {
                Text(
                    transaction.amount < 0
                    ? "-$\(abs(transaction.amount), specifier: "%.2f")"
                    : "$\(transaction.amount, specifier: "%.2f")"
                )
                .font(.caption)
                .foregroundColor(
                    transaction.amount < 0
                    ? Color(#colorLiteral(
                        red: 0.768627451,
                        green: 0.07058823529,
                        blue: 0.1921568627,
                        alpha: 1
                    ))
                    : Color(#colorLiteral(
                        red: 0.3294117647,
                        green: 0.3568627451,
                        blue: 0.3921568627,
                        alpha: 1
                    ))
                )
                
                if let balance = runningBalance {
                    Text("$\(balance, specifier: "%.2f")")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 10)
    }
    
    // Helper for a shorter date format (e.g., "Mar 22")
    private func shortDateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct TransactionRow_Previews: PreviewProvider {
    static var previews: some View {
        TransactionRow(
            transaction: Transaction(
                id: UUID(),
                parentCategory: "Food",
                subCategory: "Lunch",
                description: "Restaurant",
                date: Date(),
                amount: -15.50,
                accountID: UUID(),
                type: "expense",
                ledgerGroup: "Personal",
                payee: "Joe's Diner",
                notes: nil
            ),
            runningBalance: 100.00,
            selectedGrouping: "Month",
            showPayFrom: true
            // incomeDescriptionColor: Color.blue // Customize as needed
        )
        .previewLayout(.sizeThatFits)
    }
}
