//
//  DashboardView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/3/25.
//  3/14/25 V1.0 - Working version
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var transactionStore = TransactionStore()
    @StateObject private var accountStore = AccountStore()
    @AppStorage("selectedLedgerGroup") private var selectedLedgerGroup: String = UserDefaults.standard.getLedgers().first ?? ""
    @State private var existingLedgers: [String] = UserDefaults.standard.getLedgers()
    // Add a new state variable for showing the ledger manager
    @State private var showLedgerManager: Bool = false
    
    @State private var showAccountsDetail: Bool = false
    @State private var showExpenseTransaction: Bool = false
    @State private var showBudgetCategories: Bool = false
    @State private var showIncomeTransaction: Bool = false
    @State private var isTrendView = true
    
    @State private var totalExpenses: String = "$0.00"
    @State private var totalIncome: String = "$0.00"
    @State private var totalBills: String = "$0.00"
    @State private var showBillsView: Bool = false
    
    private var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    // MARK: - Total Net Worth Calculation
    private var totalNetWorth: String {
        let accounts = accountStore.accounts
        let filteredAccounts = accounts.filter {
            $0.ledgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
            selectedLedgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let totalAssets = filteredAccounts
            .filter { ["debit", "savings", "investments", "cash"].contains($0.type.lowercased()) }
            .map { $0.openingBalance + UserDefaults.standard.getTransactions(for: $0.id).map { $0.amount }.reduce(0, +) }
            .reduce(0, +)
        
        let totalLiabilities = filteredAccounts
            .filter { $0.type.lowercased() == "credit" }
            .map { $0.openingBalance + UserDefaults.standard.getTransactions(for: $0.id).map { $0.amount }.reduce(0, +) }
            .reduce(0, +)
        
        let netWorth = totalAssets - totalLiabilities
        return String(format: "$%.2f", netWorth)
    }
    
    // MARK: - Total Allocated Budget
    private var totalAllocatedBudget: String {
        let budgets = CategoryStorage.getBudgets()
        let filteredBudgets = budgets.filter {
            ($0.ledgerGroup ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
            selectedLedgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let totalBudget = filteredBudgets.map { $0.allocatedAmount }.reduce(0, +)
        return String(format: "$%.2f", totalBudget)
    }
    
    // MARK: - Spent Percentage (for Budget Progress Circle)
    @State private var spentPercentage: CGFloat = 0.0
    
    private var remainingBudgetString: String {
        let budgets = CategoryStorage.getBudgets().filter {
            ($0.ledgerGroup ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
            selectedLedgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let totalBudget = budgets.map { $0.allocatedAmount }.reduce(0, +)
 
        let transactions = transactionStore.transactions(forLedger: selectedLedgerGroup).filter {
            $0.type == .expense
        }
    let calendar = Calendar.current
    let currentComponents = calendar.dateComponents([.year, .month], from: Date())

    let currentMonthExpenses = transactions.filter {
        let txnComponents = calendar.dateComponents([.year, .month], from: $0.date)
        return txnComponents.year == currentComponents.year && txnComponents.month == currentComponents.month
    }
    let spentAmount = currentMonthExpenses.map { abs($0.amount) }.reduce(0, +)
 
        let remaining = max(0, totalBudget - spentAmount)
        return String(format: "$%.2f", remaining)
    }
    
    private var spentAmount: Double {
        let transactions = transactionStore.transactions(forLedger: selectedLedgerGroup).filter {
            $0.type == .expense
        }

        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month], from: Date())

        return transactions.filter {
            let txnComponents = calendar.dateComponents([.year, .month], from: $0.date)
            return txnComponents.year == currentComponents.year && txnComponents.month == currentComponents.month
        }
        .map { abs($0.amount) }
        .reduce(0, +)
    }

    private var trendData: [TrendRow] {
        let calendar = Calendar.current
        let transactions = transactionStore.transactions(forLedger: selectedLedgerGroup)
    let currentDate = Calendar.current.startOfDay(for: Date())
        let pastThreeMonths = (0..<3).compactMap {
            calendar.date(byAdding: .month, value: -$0, to: currentDate)
        }

        return pastThreeMonths.map { date in
            let comps = calendar.dateComponents([.year, .month], from: date)
            let monthName = DateFormatter().monthSymbols[(comps.month ?? 1) - 1]
            let year = comps.year ?? 0
            
            let monthTransactions = transactions.filter {
                let txnComps = calendar.dateComponents([.year, .month], from: $0.date)
                let transactionDay = calendar.startOfDay(for: $0.date)
                return transactionDay <= currentDate && txnComps.month == comps.month && txnComps.year == comps.year
            }
            
            let income = monthTransactions.filter { $0.type == .income }.map { $0.amount }.reduce(0, +)
            let expense = monthTransactions.filter { $0.type == .expense }.map { abs($0.amount) }.reduce(0, +)
            
            return TrendRow(month: "\(monthName.prefix(3)) \(year)", income: income, expense: expense)
        }
    }

    private var forecastData: [TrendRow] {
        let calendar = Calendar.current
        let allTransactions = transactionStore.transactions(forLedger: selectedLedgerGroup)
        let now = Date()
        
        let monthsToShow = (0..<3).compactMap {
            calendar.date(byAdding: .month, value: $0, to: now)
        }
        
        return monthsToShow.map { date in
            let comps = calendar.dateComponents([.year, .month], from: date)
            let monthName = DateFormatter().monthSymbols[(comps.month ?? 1) - 1]
            let year = comps.year ?? 0
            
            let forecastTransactions = allTransactions.filter {
                let txnComps = calendar.dateComponents([.year, .month], from: $0.date)
                return txnComps.month == comps.month && txnComps.year == comps.year
            }
            
            let income = forecastTransactions
                .filter { $0.type == .income }
                .map { $0.amount }
                .reduce(0, +)

            let expense = forecastTransactions
                .filter { $0.type == .expense }
                .map { abs($0.amount) }
                .reduce(0, +)
            
            return TrendRow(month: "\(monthName.prefix(3)) \(year)", income: income, expense: expense)
        }
    }
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
                .edgesIgnoringSafeArea(.all)
           
            VStack {
                HStack(spacing: 10) {
                    
                    Menu {
                        // NEW BUTTON for adding a ledger
                        Button(action: {
                            showLedgerManager = true
                        }) {
                            Text("Add New ledger")
                        }
                        
                        Divider()
                        
                        // Existing list of ledgers
                        ForEach(existingLedgers, id: \.self) { ledger in
                            Button(action: {
                                selectedLedgerGroup = ledger
                            }) {
                                Text(ledger)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedLedgerGroup.isEmpty ? "Ledger" : selectedLedgerGroup)
                                .foregroundColor(Color(#colorLiteral(red: 0.2470588235, green: 0.2901960784, blue: 0.3490196078, alpha: 1))) // #3f4a59
                                .font(.caption2)
                                .scaledToFit()
                            Image(systemName: "chevron.down")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 5, height: 5)
                                .foregroundColor(Color(#colorLiteral(red: 0.2470588235, green: 0.2901960784, blue: 0.3490196078, alpha: 1))) // #3f4a59
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 20)
                        
                       
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .resizable()
                            .frame(width: 18, height: 18)
                            .foregroundColor(Color(#colorLiteral(red: 0.2470588235, green: 0.2901960784, blue: 0.3490196078, alpha: 1))) // #3f4a59
                            .padding(.horizontal, 20)
                    }
                }
                
                VStack(spacing: 0) {
                    Divider().frame(width: 100)
                        .padding(5)
                    Text("Dashboard")
                        .font(.subheadline)
                        .padding(.horizontal, 30)
                        .foregroundColor(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                    Divider().frame(width: 100)
                        .padding(5)
                    
                    Divider() // Divider Above the MonthYear date
                        .frame(height: 0.5)
                    
                    Text(currentMonthYear)
                        .font(.caption2)
                        .foregroundColor(Color(#colorLiteral(red: 0.2470588235, green: 0.2901960784, blue: 0.3490196078, alpha: 1))) // #3f4a59
                        .padding(.top, 5)
                }
                
                Divider() // Divider above the Budet Cards
                    .padding(.horizontal)
                
                // First Card: Expenses / Income, Accounts / Bills
                VStack(spacing: 5) {
                    HStack(spacing: 3) {
                        Button(action: { showExpenseTransaction = true }) {
                            budgetCard(title: "Expenses", amount: totalExpenses)
                        }
                        Divider()
                        Button(action: { showIncomeTransaction = true }) {
                            budgetCard(title: "Income", amount: totalIncome)
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    HStack(spacing: 7) {
                        Button(action: { showAccountsDetail = true }) {
                            budgetCard(title: "Accounts", amount: totalNetWorth)
                        }
                    Divider()
                        Button(action: { showBillsView = true }) {
                            budgetCard(title: "Bills", amount: totalBills)
                        }
                    }
                }
                .padding()
                .frame(height: 160)
                
                Divider() // Divider below Budget Cards
                    .padding(.horizontal)
                
                // Second Card: Budget Summary
                VStack(spacing: 20) {
                    Button(action: { showBudgetCategories = true }) {
                        VStack {
                            Text("Budget")
                                .font(.subheadline)
                                .foregroundColor(Color(#colorLiteral(red: 0.2470588235, green: 0.2901960784, blue: 0.3490196078, alpha: 1))) // #3f4a59
                            
                            HStack(spacing: 4) {
                                Text(totalAllocatedBudget)
                                    .foregroundColor(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                                    .font(.subheadline)
                                    .padding(10)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                            }
                        }
                    }
                    
                    // Budget Progress Summary
                    VStack(alignment: .center, spacing: 8) {
                        Text("\(Int(spentPercentage * 100))%")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(Color(#colorLiteral(red: 0.549, green: 0.596, blue: 0.655, alpha: 1)))
                        
                        ProgressView(value: Double(spentPercentage), total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995)))) // #012169 80% Opacity
                            .frame(height: 20)
                            .scaleEffect(x: 1, y: 2)
                        HStack {
                            Text("Used: \(String(format: "$%.2f", spentAmount))")
                                .font(.caption2)
                                .foregroundColor(Color(#colorLiteral(red: 0.549, green: 0.596, blue: 0.655, alpha: 1)))
                            Spacer()
                            Text("Available: \(remainingBudgetString)")
                                .font(.caption2)
                                .foregroundColor(Color(#colorLiteral(red: 0.549, green: 0.596, blue: 0.655, alpha: 1)))
                        }
                    }
                    .padding(.horizontal)
                    
                    
                   
                }
                .padding()
                .frame(height: 200)
                Divider() // Divider below Budgt Section
                    .padding(.horizontal)
                
                // Third Card: Trend Overview
                VStack(spacing: 16) {
                    Text("Financial Analysis")
                        .font(.subheadline)
                        .foregroundColor(Color(#colorLiteral(red: 0.2470588235, green: 0.2901960784, blue: 0.3490196078, alpha: 1))) // #3f4a59
                    
                    HStack(spacing: 0) {
                        Button(action: { isTrendView = true }) {
                            Text("Trend")
                                .font(.caption2)
                                .fontWeight(isTrendView ? .bold : .regular)
                                .foregroundColor(isTrendView ? Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1)) : Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .background(isTrendView ? Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995)) : Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1)))
                                .cornerRadius(6, corners: [.topLeft, .bottomLeft])
                        }
                        
                        Button(action: { isTrendView = false }) {
                            Text("Forecast")
                                .font(.caption2)
                                .fontWeight(!isTrendView ? .bold : .regular)
                                .foregroundColor(!isTrendView ? Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1)) : Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995))) // #012169 80% Opacity
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .background(!isTrendView ? Color(#colorLiteral(red: 0.003921568627, green: 0.1294117647, blue: 0.4117647059, alpha: 0.7995)) : Color(#colorLiteral(red: 0.9490196078, green: 0.9725490196, blue: 0.9921568627, alpha: 1)))
                                .cornerRadius(6, corners: [.topRight, .bottomRight])
                        }
                        
                    }
                
                    HStack {
                        Divider().frame(height:20)
                        Text("Month").bold()
                        Divider().frame(height:20)
                        Text("Income").bold()
                        Divider().frame(height:20)
                        Text("Expenses").bold()
                        Divider().frame(height:20)
                        Text("Balance").bold()
                        Divider().frame(height:20)
                    }
                    .font(.caption2)
                    .padding(.horizontal, 20)
                    
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(isTrendView ? trendData : forecastData, id: \.month) { data in
                                HStack(spacing: 0) {
                                    Group {
                                        Text(data.month)
                                            .frame(maxWidth: .infinity)
                                            .padding(8)
                                            .border(Color.gray.opacity(0.4), width: 0.5)
                                        
                                        Text(String(format: "%.2f", data.income))
                                            .frame(maxWidth: .infinity)
                                            .padding(8)
                                            .border(Color.gray.opacity(0.4), width: 0.5)
                                        
                                        Text(String(format: "%.2f", data.expense))
                                            .frame(maxWidth: .infinity)
                                            .padding(8)
                                            .border(Color.gray.opacity(0.4), width: 0.5)
                                        
                                        Text(String(format: "%.2f", data.balance))
                                            .frame(maxWidth: .infinity)
                                            .padding(8)
                                            .border(Color.gray.opacity(0.4), width: 0.5)
                                    }
                                    .font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(height: 120)
                }
                .padding()
                
                Spacer()
                Divider()
                Spacer()
            }
            // MARK: - onAppear / onReceive
            .onAppear {
            transactionStore.loadAll()
                accountStore.loadAccounts()
                refreshTotalExpenses()
                refreshTotalIncome()
                refreshTotalBills()
                spentPercentage = calculateSpentPercentage()
            }
            .onReceive(NotificationCenter.default.publisher(for: .accountsUpdated)) { _ in
                accountStore.loadAccounts()
                existingLedgers = UserDefaults.standard.getLedgers()
                spentPercentage = calculateSpentPercentage()
            }
            .onReceive(NotificationCenter.default.publisher(for: .transactionUpdated)) { _ in
                transactionStore.loadAll()
                existingLedgers = UserDefaults.standard.getLedgers()
                refreshTotalExpenses()
                refreshTotalIncome()
                refreshTotalBills()
                spentPercentage = calculateSpentPercentage()
            }
            .onChange(of: selectedLedgerGroup) { _, _ in
                transactionStore.loadAll()
                refreshTotalExpenses()
                refreshTotalIncome()
                refreshTotalBills()
                spentPercentage = calculateSpentPercentage()
            }
        }
        // MARK: - Sheets
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showLedgerManager) {
            LedgerManagerView() // Replace with your actual ledger manager view.
        }
        .sheet(isPresented: $showExpenseTransaction) {
            ExpenseTransactionView(ledgerGroup: selectedLedgerGroup)
        }
        .sheet(isPresented: $showAccountsDetail) {
            AccountsDetailView(ledgerGroup: selectedLedgerGroup)
        }
        .sheet(isPresented: $showBudgetCategories) {
            CategoriesView(ledgerGroup: selectedLedgerGroup, categoryStore: CategoryStore(ledgerGroup: selectedLedgerGroup))
        }
        .sheet(isPresented: $showIncomeTransaction) {
            IncomeView(ledgerGroup: selectedLedgerGroup)
        }
        .sheet(isPresented: $showBillsView) {
            BillsView(selectedLedgerGroup: selectedLedgerGroup, transactionStore: transactionStore)
        }
    }
    
    // MARK: - Helper Function for Filtering
    private func filteredTransactions(for type: TransactionType) -> [Transaction] {
        let transactions = transactionStore.transactions(forLedger: selectedLedgerGroup)
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month], from: Date())
        
        return transactions.filter { transaction in
            let transactionComponents = calendar.dateComponents([.year, .month], from: transaction.date)
            return transaction.type == type &&
                   transaction.ledgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                   selectedLedgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) &&
                   transactionComponents.year == currentComponents.year &&
                   transactionComponents.month == currentComponents.month
        }
    }
    
    // MARK: - Refresh Total Expenses
    private func refreshTotalExpenses() {
        let expenseTransactions = filteredTransactions(for: .expense)
        let total = expenseTransactions.map { abs($0.amount) }.reduce(0, +)
        
        DispatchQueue.main.async {
            totalExpenses = String(format: "$%.2f", total)
        }
    }
    
    // MARK: - Refresh Total Income
    private func refreshTotalIncome() {
        let incomeTransactions = filteredTransactions(for: .income)
        let total = incomeTransactions.map { $0.amount }.reduce(0, +)
        
        DispatchQueue.main.async {
            totalIncome = String(format: "$%.2f", total)
        }
    }
    
    // MARK: - Refresh Total Bills
    private func refreshTotalBills() {
        let billTransactions = filteredTransactions(for: .expense).filter {
            $0.parentCategory.lowercased() == "bills"
        }
        let total = billTransactions.map { abs($0.amount) }.reduce(0, +)
        DispatchQueue.main.async {
            totalBills = String(format: "$%.2f", total)
        }
    }
    
    // MARK: - Budget Card Subview (Titles and Amount)
    private func budgetCard(title: String, amount: String) -> some View {
        VStack(spacing: 1) {
            Text(title)
                .font(.caption2)
                .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
            Text(amount)
                .font(.caption)
                .bold()
        }
        .frame(maxWidth: 120, minHeight: 35)
        .foregroundColor(Color(#colorLiteral(red: 0.2470588235, green: 0.2901960784, blue: 0.3490196078, alpha: 1))) // #3f4a59
    }

    private func calculateSpentPercentage() -> CGFloat {
        let budgets = CategoryStorage.getBudgets().filter {
            ($0.ledgerGroup ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
            selectedLedgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let totalBudget = budgets.map { $0.allocatedAmount }.reduce(0, +)

        let transactions = transactionStore.transactions(forLedger: selectedLedgerGroup).filter {
            $0.type == .expense
        }
        
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month], from: Date())
        
        let currentMonthExpenses = transactions.filter {
            let txnComponents = calendar.dateComponents([.year, .month], from: $0.date)
            return txnComponents.year == currentComponents.year && txnComponents.month == currentComponents.month
        }
        let spentAmount = currentMonthExpenses.map { abs($0.amount) }.reduce(0, +)
        return totalBudget > 0 ? min(spentAmount / totalBudget, 1.0) : 0
    }
}

// MARK: - Trend and Forecast Models
struct TrendRow {
    let month: String
    let income: Double
    let expense: Double
    var balance: Double {
        income - expense
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

        //Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
