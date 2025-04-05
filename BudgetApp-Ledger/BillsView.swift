//
//  BillsView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/25/25.
//

import SwiftUI

struct BillsView: View {
    var selectedLedgerGroup: String
    @ObservedObject var transactionStore: TransactionStore
    @Environment(\.dismiss) var dismiss
    
    // The currently displayed month in the top bar
    @State private var currentDate = Date()
    
    // For adding or editing a bill
    @State private var showAddBill = false
    @State private var selectedTransaction: Transaction? = nil
    
    // ScrollViewReader ID
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    private var calendar: Calendar { Calendar.current }
    
    // Display the month-year of currentDate
    private var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: currentDate)
    }
    
    // All “bills” for the selected ledger group in the current month/year
    private var bills: [Transaction] {
        transactionStore.transactions(forLedger: selectedLedgerGroup)
            .filter { transaction in
                transaction.type == .expense
                && transaction.parentCategory.lowercased().contains("bills")
                && calendar.isDate(transaction.date, equalTo: currentDate, toGranularity: .month)
            }
            .sorted { $0.date > $1.date }
    }
    
    // Sum the amounts of the filtered bills
    private var totalBills: Double {
        bills.map { abs($0.amount) }.reduce(0, +)
    }
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)) // #FFFFFF
                    .ignoresSafeArea()
                
                VStack(spacing: 3) {
                    // Centered "Bills" header
                    Text("Bills")
                        .font(.headline)
                        .foregroundColor(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                        .padding(.top, 16)
                    Spacer().frame(height: 4)
                    
                    // Month Navigation Bar
                    Spacer()
                    Divider()
                        .frame(height: 0.5)
                        .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                        .padding(.horizontal)
                    monthNavigationBar
                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1))) // #8C98A7
                    Divider()
                        .frame(height: 0.5)
                        .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    
                    // Functional mini-calendar
                    calendarGridView
                    Divider()
                        .frame(height: 0.5)
                        .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                    
                    // Show total bills for the month
                    Divider().frame(width: 100, height: 0.5)
                        .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                    Text(String(format: "%.2f", totalBills))
                        .foregroundColor(Color(#colorLiteral(red: 0.8901960784, green: 0.09411764706, blue: 0.2156862745, alpha: 1))) // #E31837
                        .font(.headline)
                        .padding(.top, 5)
                        .padding(.bottom, 5)
                    Divider().frame(width: 100, height: 0.5)
                        .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                    
                    // Bills List using ScrollViewReader
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(monthYear)
                                    .font(.caption)
                                    .foregroundColor(Color(#colorLiteral(red: 0.3294117647, green: 0.3568627451, blue: 0.3921568627, alpha: 1))) // #545B64
                                    .padding(.horizontal)

                                ForEach(bills) { bill in
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))
                                            .shadow(color: Color.gray.opacity(0.3), radius: 2, x: 0, y: 1)

                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("\(bill.subCategory ?? "") - \(bill.parentCategory)")
                                                    .font(.caption)
                                                    .foregroundColor(Color(#colorLiteral(red: 0.3294117647, green: 0.3568627451, blue: 0.3921568627, alpha: 1))) // #545B64
                                                Text(shortDateFormatted(bill.date))
                                                    .font(.caption2)
                                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1))) // #8C98A7
                                            }
                                            Spacer()
                                            if bill.date > Date() {
                                                Text("Upcoming")
                                                    .font(.caption2)
                                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1))) // #8C98A7
                                            } else {
                                                Text("Paid")
                                                    .font(.caption2)
                                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1))) // #8C98A7
                                            }
                                            Text("$\(abs(bill.amount), specifier: "%.2f")")
                                                .font(.caption)
                                                .foregroundColor(Color(#colorLiteral(red: 0.8901960784, green: 0.09411764706, blue: 0.2156862745, alpha: 1))) // #E31837
                                        }
                                        .padding()
                                    }
                                    .onTapGesture {
                                        selectedTransaction = bill
                                    }
                                    .padding(.horizontal)
                                    .id(Calendar.current.component(.day, from: bill.date))
                                }
                            }
                            .padding()
                        }
                        .onAppear {
                            scrollProxy = proxy
                        }
                    }
                    
                    Spacer()
                }
                
                // Floating Plus (+) Button to open AddExpenseTransactionView
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            showAddBill = true
                        }) {
                            Image(systemName: "plus.circle")
                                .imageScale(.large)
                                .foregroundColor(Color(#colorLiteral(red: 0.8901960784, green: 0.09411764706, blue: 0.2156862745, alpha: 1))) // #E31837
                                .padding(.bottom, 5)
                        }
                        .padding(.horizontal, 20)
                    }
                    Divider()
                        .frame(height: 0.5)
                        .background(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                        .padding(.horizontal)
                        .padding(.bottom, 25)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            transactionStore.load(forLedgerGroup: selectedLedgerGroup)
        }
        // Sheet for adding a new bill
        .sheet(isPresented: $showAddBill) {
            AddExpenseTransactionView(
                ledgerGroup: selectedLedgerGroup,
                onSave: { _ in
                    transactionStore.load(forLedgerGroup: selectedLedgerGroup)
                }
            )
        }
        // Sheet for editing an existing bill
        .sheet(item: $selectedTransaction) { txn in
            AddExpenseTransactionView(
                ledgerGroup: selectedLedgerGroup,
                existingTransaction: txn,
                onSave: { _ in
                    transactionStore.load(forLedgerGroup: selectedLedgerGroup)
                }
            )
        }
    }
    
    // MARK: - Month Navigation Bar
    private var monthNavigationBar: some View {
        HStack {
            Button(action: {
                if let prev = calendar.date(byAdding: .month, value: -1, to: currentDate) {
                    currentDate = prev
                    loadBills()
                }
            }) {
                Image(systemName: "chevron.left.circle")
                    .imageScale(.medium)
                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1))) // #8C98A7
            }
           
            Text(monthYear)
                .font(.subheadline)
           
            Button(action: {
                if let next = calendar.date(byAdding: .month, value: 1, to: currentDate) {
                    currentDate = next
                    loadBills()
                }
            }) {
                Image(systemName: "chevron.right.circle")
                    .imageScale(.medium)
                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1))) // #8C98A7
            }
        }
        .padding(.vertical, 5)
    }
    
    // MARK: - Functional Mini-Calendar
    private var calendarGridView: some View {
        let days = daysInMonth(for: currentDate)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                if day == 0 {
                    Text("") // Empty cell for leading offset
                } else {
                    Button(action: {
                        scrollToDay(day)
                    }) {
                        Text("\(day)")
                            .font(.caption2)
                            .frame(maxWidth: .infinity)
                            .padding(4)
                            .background(Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)))
                            .cornerRadius(4)
                    }
                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1))) // #8C98A7
                }
            }
        }
        .padding(.horizontal, 40)
    }
    
    // MARK: - Helpers
    
    private func daysInMonth(for date: Date) -> [Int] {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        let range = calendar.range(of: .day, in: .month, for: firstOfMonth)!
        let numDays = range.count
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingBlanks = weekday - 1  // Assuming Sunday = 1
        let blanks = Array(repeating: 0, count: leadingBlanks)
        let daysArray = (1...numDays).map { $0 }
        return blanks + daysArray
    }
    
    private func scrollToDay(_ day: Int) {
        guard let scrollProxy = scrollProxy else { return }
        scrollProxy.scrollTo(day, anchor: .top)
    }
    
    private func loadBills() {
        let oldDate = currentDate
        currentDate = oldDate
    }
    
    private func shortDateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct BillsView_Previews: PreviewProvider {
    static var previews: some View {
        BillsView(selectedLedgerGroup: "Sample Ledger", transactionStore: TransactionStore())
    }
}
