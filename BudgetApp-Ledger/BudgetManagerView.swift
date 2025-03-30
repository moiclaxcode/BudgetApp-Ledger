//
//  BudgetManagerView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/4/25. (Last updated 3/8/25. 9.19am
//  (Last updated 3/9/25. 6:57pm Key refinements: Redesigned the layout, added progress bar for budgets and small visual enhancements.
//  Next to work on: row tapping to open the BudgetDetailView > AddExpenseTransactionView
//  3/11/25 V1.0 - Working version (Might be need to be disable or deleted)

// import SwiftUI

// struct BudgetManagerView: View {
//     @State private var budgets: [Budget] = CategoryStorage.getBudgets()
//     @State private var showAddBudgetView = false
//     @State private var editingBudget: Budget?
//     @State private var showEditBudgetView = false
//     @State private var showDeleteConfirmation = false
//     @State private var budgetToDelete: Budget?
//     @State private var selectedLedgerGroup: String = "All" // ✅ Default to show all

//     var filteredBudgets: [Budget] {
//         budgets.filter { selectedLedgerGroup == "All" || $0.ledgerGroup == selectedLedgerGroup }
//     }

//     var groupedBudgets: [String: [Budget]] {
//         Dictionary(grouping: filteredBudgets, by: { $0.type }) // ✅ Grouped by Type (Expense/Income)
//     }

//     var totalBudget: Double {
//         filteredBudgets.reduce(into: 0.0) { $0 += $1.allocatedAmount } // Calculate total budget with safe unwrapping
//     }

//     var body: some View {
//         NavigationView {
//             VStack {
//                 // ✅ Ledger Group Picker to filter budgets
//                 Picker("Ledger Group", selection: $selectedLedgerGroup) {
//                     Text("All")
//                 }
//                 .pickerStyle(MenuPickerStyle()) // ✅ Updated to menu style for better usability
//                 .padding()
                
//                 // ✅ Total Budget display with rounded rectangle background
//                 VStack {
//                     Text("Total Budget")
//                         .font(.subheadline) // Reduced font size
//                         .foregroundColor(.gray)
//                     Text("$\(totalBudget, specifier: "%.2f")") // Display total budget
//                         .font(.headline) // Reduced font size
//                         .foregroundColor(.black)
//                 }
//                 .padding()
//                 .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).shadow(radius: 1)) // Fixed background and added shadow
//                 .padding(.horizontal, 20) // Added horizontal padding for better spacing

//                 if filteredBudgets.isEmpty {
//                     Text("Add Budget")
//                         .foregroundColor(.gray)
//                         .padding()
//                 } else {
//                     List {
//                         ForEach(groupedBudgets.keys.sorted(), id: \.self) { type in
//                             Section(header: Text(type)
//                                 .font(.footnote) // ✅ Made header smaller
//                                 .foregroundColor(.gray)
//                                 .textCase(.none)
//                             ) {
//                                 ForEach(groupedBudgets[type] ?? []) { budget in
//                                     budgetRow(budget)
//                                 }
//                             }
//                         }
//                         .onMove { source, destination in
//                             moveBudget(from: source, to: destination)
//                         }
//                     }
//                     .listStyle(InsetGroupedListStyle())
//                 }
//             }
//             .navigationBarTitle("Budget", displayMode: .inline)
//             .navigationBarItems(
//                 leading: EditButton(),
//                 trailing: Button(action: { showAddBudgetView = true }) {
//                     Image(systemName: "plus")
//                 }
//             )
//             .onAppear {
//                 refreshBudgets()
//             }
//             .sheet(isPresented: $showAddBudgetView) {
//                 AddBudgetView { newBudget in
//                     budgets.append(newBudget)
//                     saveBudgets()
//                     showAddBudgetView = false
//                     NotificationCenter.default.post(name: .budgetsUpdated, object: nil) // ✅ Sync with other views
//                 }
//             }
//             .sheet(isPresented: Binding(
//                 get: { showEditBudgetView && editingBudget != nil },
//                 set: { if !$0 { showEditBudgetView = false; editingBudget = nil } }
//             )) {
//                 if let editingBudget = editingBudget {
//                     EditBudgetView(budget: editingBudget) { updatedBudget in
//                         updateBudget(updatedBudget)
//                         showEditBudgetView = false
//                         NotificationCenter.default.post(name: .budgetsUpdated, object: nil) // ✅ Sync with other views
//                     }
//                 }
//             }
//             .alert(isPresented: $showDeleteConfirmation) {
//                 Alert(
//                     title: Text("Delete Budget"),
//                     message: Text("Are you sure you want to delete this budget?"),
//                     primaryButton: .destructive(Text("Delete")) {
//                         if let budgetToDelete = budgetToDelete {
//                             deleteBudget(budgetToDelete)
//                         }
//                     },
//                     secondaryButton: .cancel()
//                 )
//             }
//         }
//     }

//     private func budgetRow(_ budget: Budget) -> some View {
//         HStack {
//             Text(budget.categoryName) // ✅ Category Name first
//                 .font(.caption)
//                 .foregroundColor(.gray)

//             Text(" - \(budget.description)") // ✅ Description to the right
//                 .font(.caption)

//             Spacer()

//             Text("$\(budget.allocatedAmount, specifier: "%.2f")") // Display budget amount next to ellipsis menu
//                 .font(.caption)
//                 .foregroundColor(.gray)

//             Menu {
//                 Button("Edit", action: {
//                     editingBudget = budget
//                     DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                         showEditBudgetView = true
//                     }
//                 })
//                 Button("Delete", role: .destructive, action: {
//                     budgetToDelete = budget
//                     showDeleteConfirmation = true
//                 })
//             } label: {
//                 Image(systemName: "ellipsis")
//                     .foregroundColor(.gray)
//                     .padding(.leading, 8)
//             }
//         }
//         .padding(.vertical, 6)
//         .padding(.bottom, 12) // Added padding between the budget category name and the progress bar
//         .overlay(
//             ProgressView(value: spentAmount(for: budget), total: budget.allocatedAmount)
//                 .progressViewStyle(LinearProgressViewStyle())
//                 .frame(height: 12)
//                 .padding(.top, 12)
//         )
//     }

//     private func saveBudgets() {
//         CategoryStorage.saveBudget(budgets)
//         NotificationCenter.default.post(name: .budgetsUpdated, object: nil) // ✅ Notify views to update
//     }

//     private func deleteBudget(_ budget: Budget) {
//         CategoryStorage.deleteBudget(budget)
//         NotificationCenter.default.post(name: .budgetsUpdated, object: nil) // ✅ Ensure deletion syncs
//     }

//     private func updateBudget(_ updatedBudget: Budget) {
//         if let index = budgets.firstIndex(where: { $0.id == updatedBudget.id }) {
//             budgets[index] = updatedBudget
//             saveBudgets()
//         }
//     }

//     private func moveBudget(from source: IndexSet, to destination: Int) {
//         budgets.move(fromOffsets: source, toOffset: destination)
//         saveBudgets()
//     }

//     private func refreshBudgets() {
//         budgets = CategoryStorage.getBudgets()
//     }
    
//     private func spentAmount(for budget: Budget) -> Double {
//         let transactions = CategoryStorage.getExpenseTransactions()
//         return transactions
//             .filter { $0.category == budget.categoryName }
//             .reduce(0.0) { $0 + abs($1.amount) } // ✅ Sum all expenses for this category
//     }
// }

// ✅ Ensure `budgetsUpdated` notification exists globally
// extension Notification.Name {
//     static let budgetsUpdated = Notification.Name("budgetsUpdated")
// }
