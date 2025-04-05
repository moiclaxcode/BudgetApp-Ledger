//
//  CategoriesView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/9/25 - 10:20pm.
//  3/14/25 V1.0 - Working version (Plain List with custom row styling)
//

import SwiftUI

// Wrapper struct to make a String identifiable for sheet presentation.
struct IdentifiableCategory: Identifiable {
    let id = UUID()
    let name: String
}

struct CategoriesView: View {
    var ledgerGroup: String
    @ObservedObject var categoryStore: CategoryStore
    @State private var categories: [String] = []
    @State private var newCategoryName: String = ""
    @State private var isAddingCategory: Bool = false // Controls visibility of text field
    @FocusState private var isTextFieldFocused: Bool // Focus state for keyboard
    @State private var editingCategoryIndex: Int? = nil
    @State private var showDeleteConfirmation = false
    @State private var categoryToDelete: Int?
    @State private var editedCategoryName: String = ""
    @State private var selectedCategory: IdentifiableCategory? = nil // For sheet presentation
    
    // New state variable for ledger group selection in the form.
    @State private var selectedLedgerGroupForCategory: String = ""
    
    private var totalCategoryBudget: Double {
        let budgets = CategoryStorage.getBudgets()
        let filteredBudgets = budgets.filter {
            ($0.ledgerGroup ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
            ledgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return filteredBudgets.reduce(0.0) { $0 + $1.allocatedAmount }
    }

    private func totalSpent(for category: String) -> Double {
    let transactions = UserDefaults.standard.getTransactions(for: ledgerGroup)
    let filtered = transactions.filter {
        $0.parentCategory == category
    }
        return filtered.map { abs($0.amount) }.reduce(0, +)
    }
    
    // MARK: - Category Row View
    private func categoryRow(for index: Int) -> some View {
        HStack {
            if editingCategoryIndex == index {
                TextField("Edit Category", text: $editedCategoryName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                Button(action: { saveCategoryChanges(at: index) }) {
                    Text("Save")
                        .foregroundColor(Color(#colorLiteral(red: 0.549, green: 0.596, blue: 0.655, alpha: 1)))
                        .bold()
                }
                .padding(.leading, 8)
            } else {
                HStack {
                    VStack(alignment: .leading) {
                        Text(categories[index])
                            .font(.caption)
                            .foregroundColor(Color(#colorLiteral(red: 0.329, green: 0.357, blue: 0.393, alpha: 1)))
                        
                        ZStack(alignment: .leading) {
                            GeometryReader { geometry in
                                let total = maxBudget(for: categories[index])
                                let spent = totalSpent(for: categories[index])
                                let progress = total > 0 ? min(spent / total, 1.0) : 0
                                let barWidth = geometry.size.width
 
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 4)
 
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(#colorLiteral(red: 0.2980392157, green: 0.3058823529, blue: 0.6078431373, alpha: 0.7973665149)))
                                    .frame(width: barWidth * CGFloat(progress), height: 4)
                            }
                        }
                        .frame(width: 100, height: 4)
                    }
                    
                    Spacer()
                    
                    Text("$\(totalBudget(for: categories[index]), specifier: "%.2f")")
                        .font(.caption2)
                        .foregroundColor(Color(#colorLiteral(red: 0.549, green: 0.596, blue: 0.655, alpha: 1)))
                    
                    Menu {
                        Button("Edit", action: { startEditingCategory(at: index) })
                        Button("Delete", role: .destructive, action: { confirmDeleteCategory(at: index) })
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(Color(#colorLiteral(red: 0.549, green: 0.596, blue: 0.655, alpha: 1)))
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    // Set the selected category to open the SubcategoriesView.
                    selectedCategory = IdentifiableCategory(name: categories[index])
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Plain List for Categories
    private func categoryList() -> some View {
        Group {
            List {
                // Iterate over categories using their index.
                ForEach(Array(categories.enumerated()), id: \.element) { (index, _) in
                    categoryRow(for: index)
                }
                .onMove(perform: moveCategory)
            }
            .listStyle(InsetGroupedListStyle())
            .shadow(color: Color.gray.opacity(0.3), radius: 2, y: 1)
            .scrollContentBackground(.hidden)  // Hides default background (iOS 16+)
            .background(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))) // Customize background behind the list
            
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background for the entire view.
                Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Total Budget Display
                    Divider().frame(width: 100, height: 0.5)
                        .background(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                    Text(String(format: "$%.2f", totalCategoryBudget))
                        .font(.headline)
                        .foregroundColor(Color(#colorLiteral(red: 0.1568627451, green: 0.5019607843, blue: 0.1843137255, alpha: 1)))
                        .frame(maxWidth: .infinity, alignment: .center)
                    Divider().frame(width: 100, height: 0.5)
                        .background(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                    
                    Divider()// // Separator below the header
                        .frame(height: 0.5)
                        .background(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                        .padding(.horizontal)
                    
                    // Add Category Input Field
                    if isAddingCategory {
                        VStack {
                            // Ledger Group Selection Field
                            VStack(alignment: .center, spacing: 5) {
                                Text("Ledger")
                                    .font(.caption2)
                                    .foregroundColor(Color(#colorLiteral(red: 0.549, green: 0.596, blue: 0.655, alpha: 1)))
                                    .multilineTextAlignment(.center)
                                Menu {
                                    ForEach(UserDefaults.standard.getLedgers(), id: \.self) { ledger in
                                        Button(action: {
                                            selectedLedgerGroupForCategory = ledger
                                        }) {
                                            Text(ledger)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(selectedLedgerGroupForCategory.isEmpty ? "Select Ledger Group" : selectedLedgerGroupForCategory)
                                            .foregroundColor(selectedLedgerGroupForCategory.isEmpty ? .gray : .primary)
                                            .font(.caption2)
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
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 0.3)
                                    )
                                }
                            }
                            .padding(.horizontal)
                            HStack {
                                TextField("New Category", text: $newCategoryName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 10)
                                
                                Button("Save") {
                                    addCategory()
                                }
                                .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                .padding(.trailing, 10)
                            }
                        }
                        .padding()
                    }
                    
                    // Category List or Empty State Message
                    if categories.isEmpty {
                        Spacer()
                        VStack {
                            Text("No categories found")
                                .font(.headline)
                                .foregroundColor(Color(#colorLiteral(red: 0.549, green: 0.596, blue: 0.655, alpha: 1)))
                                .padding()
                            Text("Tap + to add a new category")
                                .font(.subheadline)
                                .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                        }
                        Spacer()
                    } else {
                        categoryList()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack {
                            Text("Categories")
                                .font(.headline)
                                .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            withAnimation {
                                isAddingCategory.toggle()
                            }
                        }) {
                            Image(systemName: "plus.circle")
                                .imageScale(.medium)
                                .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            fetchCategories()
            // Default the ledger group for the new category form to the passed-in ledgerGroup if not already set.
            if selectedLedgerGroupForCategory.isEmpty {
                selectedLedgerGroupForCategory = ledgerGroup
            }
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Category"),
                message: Text("Are you sure you want to delete this category?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let index = categoryToDelete {
                        deleteCategory(at: index)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        // Top-level sheet to present SubcategoriesView when a category row is tapped.
        .sheet(item: $selectedCategory) { category in
            SubcategoriesView(
                selectedCategory: category.name,
                ledgerGroup: ledgerGroup,
                categoryStore: categoryStore
            )
        }
    }
    
    private func fetchCategories() {
        categories = CategoryStorage.getCategoriesByLedgerGroup(ledgerGroup)
    }
    
    private func totalBudget(for category: String) -> Double {
        let budgets = CategoryStorage.getBudgets()
        let subcategoryBudgets = budgets
            .filter {
                $0.parentCategory == category &&
                ($0.ledgerGroup ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                ledgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .reduce(0.0) { $0 + $1.allocatedAmount }
        return subcategoryBudgets
    }
    
    private func maxBudget(for category: String) -> Double {
        let budgets = CategoryStorage.getBudgets()
        let categoryBudgets = budgets.filter {
            ($0.parentCategory == category) &&
            ($0.ledgerGroup ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
            ledgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let total = categoryBudgets.reduce(0.0) { $0 + $1.allocatedAmount }
        return max(total, 1)
    }
    
    private func addCategory() {
        if !newCategoryName.isEmpty {
            CategoryStorage.addCategory(newCategoryName, toLedgerGroup: selectedLedgerGroupForCategory)
            fetchCategories()
            newCategoryName = ""
            isAddingCategory = false
        }
    }
    
    private func startEditingCategory(at index: Int) {
        editingCategoryIndex = index
        editedCategoryName = categories[index]
    }
    
    private func saveCategoryChanges(at index: Int) {
        if !editedCategoryName.isEmpty {
            categories[index] = editedCategoryName
            saveCategories()
        }
        editingCategoryIndex = nil
    }
    
    private func confirmDeleteCategory(at index: Int) {
        categoryToDelete = index
        showDeleteConfirmation = true
    }
    
    private func deleteCategory(at index: Int) {
        let category = categories[index]
        CategoryStorage.deleteCategory(category, fromLedgerGroup: ledgerGroup)
        fetchCategories()
    }
    
    private func moveCategory(from source: IndexSet, to destination: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            categories.move(fromOffsets: source, toOffset: destination)
            saveCategories()
        }
    }
    
    private func saveCategories() {
        var budgets = CategoryStorage.getBudgets()
        for index in categories.indices {
            if let existingBudgetIndex = budgets.firstIndex(where: {
                $0.parentCategory == categories[index] &&
                ($0.ledgerGroup ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ==
                ledgerGroup.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            }) {
                budgets[existingBudgetIndex].allocatedAmount = totalBudget(for: categories[index])
            }
        }
        CategoryStorage.saveBudgets(budgets)
    }
}

struct CategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        CategoriesView(
            ledgerGroup: "Sample Ledger",
            categoryStore: CategoryStore(ledgerGroup: "Sample Ledger")
        )
    }
}
