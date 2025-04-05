//
//  SubcategoriesView.swift
//  BudgetApp-Ledger
//  Created by Hector on 3/10/25.
//  Updated on 3/14/25 - Modified subcategory addition process.
//  3/24/25 V1.1 - Moved subcategory field & added progress bar.
//  3/28/25 V2.0 - Refactored to use ZStack for background
//

import SwiftUI

// MARK: - A Small Struct for Identifiable Subcategories
fileprivate struct IdentifiableSubCategory: Identifiable {
    let id = UUID()
    let name: String
}

struct SubcategoriesView: View {
    var selectedCategory: String // The category that subcategories belong to
    let ledgerGroup: String      // Ledger group passed in from Dashboard
    @ObservedObject var categoryStore: CategoryStore
    
    @State private var subCategories: [String] = [] // Holds the list of subcategories
    
    // MARK: - UI State Variables
    @State private var showTextField = false       // Controls the visibility of the new subcategory text field
    @State private var newSubCategoryName = ""       // Stores the input for new subcategories
    
    // Ledger Group selection for the subcategory addition form
    @State private var selectedLedgerGroupForSubCategory: String = ""
    
    // Use IdentifiableSubCategory for sheet presentation
    @State private var selectedSubCategory: IdentifiableSubCategory? = nil
    
    // State variable to control whether to open SetBudgetView in edit mode (true) or add mode (false)
    @State private var isEditMode: Bool = false
    
    // MARK: - Initializer
    init(selectedCategory: String, ledgerGroup: String, categoryStore: CategoryStore) {
        self.selectedCategory = selectedCategory
        self.ledgerGroup = ledgerGroup
        self.categoryStore = categoryStore
        _subCategories = State(initialValue: categoryStore.getSubcategories(for: selectedCategory))
    }
    
    // MARK: - Computed Property for Total Allocated Amount
    private var totalAllocated: Double {
        subCategories.reduce(0) { $0 + getBudgetForCategory($1).allocatedAmount }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background for the entire view
                Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    ZStack {
                        Text("Subcategories")
                            .font(.headline)
                            .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                showTextField.toggle()
                            }) {
                                Image(systemName: "plus.circle")
                                    .imageScale(.large)
                                    .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    
                    // Subcategory Input Section
                    if showTextField {
                        VStack(spacing: 10) {
                            // New Ledger Group Selection Field
                            VStack(alignment: .center, spacing: 5) {
                                Text("Ledger Group")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                Menu {
                                    ForEach(UserDefaults.standard.getLedgers(), id: \.self) { ledger in
                                        Button(action: {
                                            selectedLedgerGroupForSubCategory = ledger
                                        }) {
                                            Text(ledger)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(selectedLedgerGroupForSubCategory.isEmpty ? "Select Ledger Group" : selectedLedgerGroupForSubCategory)
                                            .foregroundColor(selectedLedgerGroupForSubCategory.isEmpty ? .gray : .primary)
                                            .font(.callout)
                                        Image(systemName: "chevron.down")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 10, height: 10)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            HStack {
                                TextField("Enter subcategory name", text: $newSubCategoryName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 10)
                                
                                Button("Save") {
                                    if !newSubCategoryName.isEmpty {
                                        addSubCategory(newSubCategoryName)
                                        newSubCategoryName = ""
                                        showTextField = false
                                    }
                                }
                                .foregroundColor(Color(#colorLiteral(red: 0.549, green: 0.596, blue: 0.655, alpha: 1)))
                                .padding(.trailing, 10)
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    
                    // Display Total Allocated Amount Above the Divider
                    Divider().frame(width: 100, height: 0.5)
                        .background(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                    Text("$\(totalAllocated, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(Color(#colorLiteral(red: 0.1568627451, green: 0.5019607843, blue: 0.1843137255, alpha: 1)))
                    Divider().frame(width: 100, height: 0.5)
                        .background(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                    
                    Divider()// Divder below total
                        .frame(height: 0.5)
                        .background(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                        .padding(.horizontal)
                    
                    // Subcategory List Display
                    if subCategories.isEmpty {
                        Text("No Subcategories Found")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        List {
                            ForEach(subCategories, id: \.self) { subCategoryString in
                                // Use a Button so that tapping the row opens the sheet in add mode.
                                Button(action: {
                                    selectedSubCategory = IdentifiableSubCategory(name: subCategoryString)
                                    isEditMode = false // Tap outside menu → Add mode
                                }) {
                                    subCategoryRow(subCategoryString)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        .shadow(color: Color.gray.opacity(0.3), radius: 2, y: 1)
                        .scrollContentBackground(.hidden)  // Hide default background (iOS 16+)
                        .background(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            refreshSubCategories()
            if selectedLedgerGroupForSubCategory.isEmpty {
                selectedLedgerGroupForSubCategory = ledgerGroup
            }
        }
        // Top-level sheet presenting SetBudgetView.
        // If isEditMode is true, the view loads the existing budget for edit; if false, it creates a new budget.
        .sheet(item: $selectedSubCategory) { subCategory in
        if isEditMode {
            SetBudgetView(budget: getBudgetForCategory(subCategory.name), categoryStore: categoryStore) {
                refreshSubCategories()
            }
        } else if !isEditMode {
            let newBudget = Budget(
                parentCategory: selectedCategory,
                subCategory: subCategory.name,
                description: "",
                type: "Expense",
                budget: 0,
                ledgerGroup: ledgerGroup,
                budgetCycle: "Monthly",
                startDate: Date()
            )
            SetBudgetView(budget: newBudget, categoryStore: categoryStore) {
                refreshSubCategories()
            }
        }
        }
    }
    
    // MARK: - Budget Retrieval Function
    private func getBudgetForCategory(_ subCategoryName: String) -> Budget {
        return CategoryStorage.getBudget(forCategory: selectedCategory, subCategory: subCategoryName, ledgerGroup: ledgerGroup)
            ?? Budget(
                parentCategory: selectedCategory,
                subCategory: subCategoryName,
                description: "",
                type: "Expense",
                budget: 0,
                ledgerGroup: ledgerGroup,
                budgetCycle: "Monthly",
                startDate: Date()
            )
    }
    
    // MARK: - Calculate Spent Amount for a Budget (with ledger filtering)
    private func spentAmount(for budget: Budget) -> Double {
        let transactions = UserDefaults.standard.getTransactions(for: ledgerGroup)
        let calendar = Calendar.current
        let (startDate, endDate): (Date, Date) = {
            let now = Date()
            switch budget.budgetCycle {
            case "Monthly":
                let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
                let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? now
                return (start, end)
            case "Weekly":
                let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
                let end = calendar.date(byAdding: .day, value: 6, to: start) ?? now
                return (start, end)
            case "Yearly":
                let start = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
                let end = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: start) ?? now
                return (start, end)
            default:
                return (now, now)
            }
        }()

        let filteredTransactions = transactions.filter {
            $0.parentCategory == selectedCategory &&
            $0.subCategory == budget.subCategory &&
            $0.date >= startDate && $0.date <= endDate
        }
        return filteredTransactions.reduce(0.0) { $0 + abs($1.amount) }
    }
    
    // MARK: - Subcategory Row UI with Dynamic Progress Bar Color
    private func subCategoryRow(_ subCategory: String) -> some View {
        let budget = getBudgetForCategory(subCategory)
        let spent = spentAmount(for: budget)
        let allocated = budget.allocatedAmount
        let progress = allocated > 0 ? min(spent / allocated, 1.0) : 0
        
        // Dynamic progress color using real-time transaction data:
        let progressColor: Color
        if progress < 0.5 {
            progressColor = Color(#colorLiteral(red: 0.1568627451, green: 0.5019607843, blue: 0.1843137255, alpha: 1)) // dark green
        } else if progress < 1.0 {
            progressColor = Color(#colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)) // orange
        } else {
            progressColor = Color(#colorLiteral(red: 0.8901960784, green: 0.09411764706, blue: 0.2156862745, alpha: 1)) // red
        }
        
        return HStack {
            VStack(alignment: .leading) {
                Text(subCategory)
                    .font(.caption)
                    .foregroundColor(Color(#colorLiteral(red: 0.549, green: 0.596, blue: 0.655, alpha: 1)))
                
                ZStack(alignment: .leading) {
                    GeometryReader { geometry in
                        let barWidth = geometry.size.width
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(progressColor)
                            .frame(width: barWidth * CGFloat(progress), height: 4)
                    }
                }
                .frame(width: 100, height: 4)
                
                Text("Used: $\(spent, specifier: "%.2f")")
                    .font(.caption2)
                    .foregroundColor(Color(#colorLiteral(red: 0.549, green: 0.596, blue: 0.655, alpha: 1)))
            }
            Spacer()
            Text("$\(allocated, specifier: "%.2f")")
                .font(.caption)
                .foregroundColor(Color(#colorLiteral(red: 0.549, green: 0.596, blue: 0.655, alpha: 1)))
            
            // Ellipsis menu for editing/deleting:
            Menu {
                Button("Edit") {
                    isEditMode = true
                    selectedSubCategory = IdentifiableSubCategory(name: subCategory)
                }
                Button("Delete", role: .destructive) {
                    deleteSubCategory(subCategory)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(Color(#colorLiteral(red: 0.549, green: 0.596, blue: 0.655, alpha: 1)))
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Add a New Subcategory
    private func addSubCategory(_ subCategory: String) {
        if !subCategories.contains(subCategory) {
            subCategories.append(subCategory)
            categoryStore.saveSubcategories(for: selectedCategory, subcategories: subCategories)
            categoryStore.saveBudget(Budget(
                parentCategory: selectedCategory,
                subCategory: subCategory,
                description: "",
                type: "Expense",
                budget: 0,
                ledgerGroup: ledgerGroup,
                budgetCycle: "Monthly",
                startDate: Date()
            ))
            refreshSubCategories()
        }
    }
    
    // MARK: - Refresh Subcategories List
    private func refreshSubCategories() {
        DispatchQueue.main.async {
            self.subCategories = categoryStore.getSubcategories(for: selectedCategory)
        }
    }
    
    // MARK: - Delete a Subcategory
    private func deleteSubCategory(_ subCategory: String) {
        subCategories.removeAll { $0 == subCategory }
        categoryStore.saveSubcategories(for: selectedCategory, subcategories: subCategories)
    }
}

struct SubcategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        SubcategoriesView(selectedCategory: "Sample Category", ledgerGroup: "Sample Ledger", categoryStore: CategoryStore(ledgerGroup: "Sample Ledger"))
    }
}
