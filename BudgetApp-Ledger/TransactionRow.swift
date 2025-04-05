//
//  TransactionRow.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/6/25.
//  3/14/25 V1.1 - Updated to support payee and pay from display for expenses
//  Updated on 4/3/25 - Added statusText computed property for Upcoming/Paid
//

import SwiftUI

struct TransactionRow: View {
    var transaction: Transaction
    var runningBalance: Double? = nil
    var selectedGrouping: String
    var showPayFrom: Bool = false
    
    // MARK: - Computed: Status Text
    /// Returns "Paid" if transaction.date <= today; otherwise "Upcoming".
    private var statusText: String {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return (transaction.date < Calendar.current.date(byAdding: .day, value: 1, to: startOfToday)!) ? "Paid" : "Upcoming"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                // Top line: For expense transactions, show subcategory and payee; for income, show description
                switch transaction.type {
                case .expense:
                    let categoryText = transaction.subCategory ?? transaction.parentCategory
                    let payeeText = (transaction.payee?.isEmpty == false) ? " - \(transaction.payee!)" : ""
                    Text("\(categoryText)\(payeeText)")
                        .font(.caption)
                        .foregroundColor(Color(#colorLiteral(red: 0.3294117647,
                                                             green: 0.3568627451,
                                                             blue: 0.3921568627,
                                                             alpha: 0.7987893212)))
                    
                case .transfer:
                    let isSender = transaction.amount < 0
                    let label = isSender ? "Transfer to" : "Transfer from"
                    let otherAccountName = transaction.description
                        .replacingOccurrences(of: label + " ", with: "")
                    Text("\(label) \(otherAccountName)")
                        .font(.caption)
                        .foregroundColor(Color(#colorLiteral(red: 0.3294117647,
                                                             green: 0.3568627451,
                                                             blue: 0.3921568627,
                                                             alpha: 0.7987893212)))
                    
                default: // .income or fallback
                    Text(transaction.description.isEmpty ? "No Description" : transaction.description)
                        .font(.caption)
                        .foregroundColor(Color(#colorLiteral(red: 0.3294117647,
                                                             green: 0.3568627451,
                                                             blue: 0.3921568627,
                                                             alpha: 0.7987893212)))
                }
                
                // Second line: For expense rows, if showPayFrom is true, display date + account;
                // otherwise show short date if grouping is Month.
                if showPayFrom, let account = UserDefaults.standard.getAccount(for: transaction.accountID) {
                    HStack {
                        Text("\(shortDateFormatted(transaction.date)) – \(statusText)")
                        Text(account.name)
                    }
                    .font(.caption2)
                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078,
                                                         green: 0.5960784314,
                                                         blue: 0.6549019608,
                                                         alpha: 0.8033164321)))
                } else if selectedGrouping == "Month" || selectedGrouping == "Day" {
                    Text("\(shortDateFormatted(transaction.date)) – \(statusText)")
                        .font(.caption2)
                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078,
                                                             green: 0.5960784314,
                                                             blue: 0.6549019608,
                                                             alpha: 0.8033164321)))
                }
            }
            
            Spacer()
            
            // Amount + optional running balance
            VStack(alignment: .trailing) {
                let isCreditAccount = UserDefaults.standard
                    .getAccount(for: transaction.accountID)?
                    .type
                    .lowercased() == "credit"
                
                // For credit accounts, we show the absolute value
                // so negative amounts won't show double negatives
                let showAmount = isCreditAccount ? abs(transaction.amount) : transaction.amount
                
                Text(
                    showAmount < 0
                    ? "-$\(abs(showAmount), specifier: "%.2f")"
                    : "$\(showAmount, specifier: "%.2f")"
                )
                .font(.caption)
                .foregroundColor(
                    transaction.amount < 0
                    ? Color(#colorLiteral(red: 0.8901960784,
                                          green: 0.09411764706,
                                          blue: 0.2156862745,
                                          alpha: 1))
                    : Color(#colorLiteral(red: 0.3294117647,
                                          green: 0.3568627451,
                                          blue: 0.3921568627,
                                          alpha: 0.7987893212))
                )
                
                if let balance = runningBalance {
                    Text("$\(balance, specifier: "%.2f")")
                        .font(.caption2)
                        .foregroundColor(
                            Color(#colorLiteral(red: 0.5490196078,
                                                green: 0.5960784314,
                                                blue: 0.6549019608,
                                                alpha: 0.8033164321))
                        )
                }
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper: Short Date
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
                type: .expense,
                ledgerGroup: "Personal",
                payee: "Joe's Diner",
                notes: nil
            ),
            runningBalance: 100.00,
            selectedGrouping: "Month",
            showPayFrom: true
        )
        .previewLayout(.sizeThatFits)
    }
}
