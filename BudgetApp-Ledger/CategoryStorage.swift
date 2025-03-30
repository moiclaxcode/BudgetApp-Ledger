//
//  CategoryStorage.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/12/25.
//  3/14/25 V1.0 - Working version ?(Time I stopped making changes)

import Foundation
// MARK: - Notifications

extension NSNotification.Name {
    static let categoriesUpdated = NSNotification.Name("categoriesUpdated")
}

struct CategoryStorage {
    private static let categoriesKey = "categories"
    private static let subcategoriesKey = "subcategories"
    private static let budgetsKey = "budgetData" // New storage key for budgets

    // MARK: - Categories Management
    // Retrieves all categories, grouped by Ledger Group
    static func getCategories() -> [String: [String]] {
        let storedCategories = UserDefaults.standard.dictionary(forKey: categoriesKey) as? [String: [String]] ?? [:]

        if storedCategories.isEmpty {
            return ["Default": ["Uncategorized"]] // ✅ Prevents empty return
        }

        return storedCategories
    }

    // Saves the updated categories dictionary
    static func saveCategories(_ categories: [String: [String]]) {
        UserDefaults.standard.set(categories, forKey: categoriesKey)
    }

    // Adds a new category under a specific Ledger Group
    static func addCategory(_ category: String, toLedgerGroup ledgerGroup: String) {
        var categories = getCategories()

        if categories[ledgerGroup] == nil {
            categories[ledgerGroup] = []
        }

        if !categories[ledgerGroup]!.contains(category) {
            categories[ledgerGroup]!.append(category)
            saveCategories(categories)
        }

        // ✅ Immediately refresh stored data to ensure persistence
        UserDefaults.standard.synchronize()
    }

    // Deletes a category from a Ledger Group
    static func deleteCategory(_ category: String, fromLedgerGroup ledgerGroup: String) {
        var categories = getCategories()

        if var ledgerCategories = categories[ledgerGroup] {
            ledgerCategories.removeAll { $0 == category }
            categories[ledgerGroup] = ledgerCategories.isEmpty ? nil : ledgerCategories
            saveCategories(categories)
        }
    }

    // Retrieves categories for a specific Ledger Group
    static func getCategoriesByLedgerGroup(_ ledgerGroup: String) -> [String] {
        let categories = getCategories()
        return categories[ledgerGroup] ?? []
    }

    // MARK: - Subcategories Management
    // Retrieves subcategories, grouped by Ledger Group and Category
    static func getSubcategoriesByCategory() -> [String: [String]] {
        let storedSubcategories = UserDefaults.standard.dictionary(forKey: subcategoriesKey) as? [String: [String]] ?? [:]

        if storedSubcategories.isEmpty {
            return ["Uncategorized": [""]] // ✅ Ensures at least one default entry
        }

        return storedSubcategories
    }

    // Saves the updated subcategories dictionary
    static func saveSubcategoriesByCategory(_ subcategories: [String: [String]]) {
        UserDefaults.standard.set(subcategories, forKey: subcategoriesKey)
    }

    // Adds a new subcategory under a specific Category
    static func addSubcategory(_ subcategory: String, toCategory category: String) {
        var subcategories = getSubcategoriesByCategory()

        if subcategories[category] == nil {
            subcategories[category] = []
        }

        if !(subcategories[category]!.contains(subcategory)) {
            subcategories[category]!.append(subcategory)
            saveSubcategoriesByCategory(subcategories)
        }

        // ✅ Immediately refresh stored data to prevent data loss
        UserDefaults.standard.synchronize()
    }

    // Retrieves subcategories for a specific Category
    static func getSubcategories(forCategory category: String) -> [String] {
        let subcategories = getSubcategoriesByCategory()
        return subcategories[category] ?? []
    }
    
    // Deletes a subcategory from a specific Category
    static func deleteSubcategory(_ subcategory: String, fromCategory category: String) {
        var subcategories = getSubcategoriesByCategory()
        
        // Ensure the category exists
        if var categorySubcategories = subcategories[category] {
            categorySubcategories.removeAll { $0 == subcategory }
            subcategories[category] = categorySubcategories.isEmpty ? nil : categorySubcategories
            
            // Remove empty category keys
            if subcategories.isEmpty {
                subcategories.removeValue(forKey: category)
            }
            
            saveSubcategoriesByCategory(subcategories)
        }
    }

    // Saves subcategories for a specific category (Ledger Group no longer needed)
    static func saveSubcategories(forCategory category: String, subcategories: [String]) {
        var storedSubcategories = getSubcategoriesByCategory()

        // ✅ Directly update or insert the subcategories
        storedSubcategories[category] = subcategories
        saveSubcategoriesByCategory(storedSubcategories)
    }
    
    // MARK: - Budget Management
    // Retrieves all budgets
    static func getBudgets() -> [Budget] {
        guard let data = UserDefaults.standard.data(forKey: budgetsKey),
              let budgets = try? JSONDecoder().decode([Budget].self, from: data) else {
            return []
        }
        return budgets
    }

    // Saves multiple budgets
    static func saveBudgets(_ newBudgets: [Budget]) {
        if let encodedData = try? JSONEncoder().encode(newBudgets) {
            UserDefaults.standard.set(encodedData, forKey: budgetsKey)
        }
        NotificationCenter.default.post(name: .categoriesUpdated, object: nil)
    }

    // Saves or updates a single budget
    static func saveBudget(_ budget: Budget) {
        var budgets = getBudgets()

        if let index = budgets.firstIndex(where: { $0.parentCategory == budget.parentCategory && $0.subCategory == budget.subCategory }) {
            budgets[index] = budget
        } else {
            var newBudget = budget
            if newBudget.ledgerGroup == nil || newBudget.ledgerGroup == "All" {
                newBudget.ledgerGroup = budgets.first(where: { $0.parentCategory == budget.parentCategory })?.ledgerGroup ?? budget.ledgerGroup
            }
            budgets.append(newBudget)
        }

        // Aggregate total budget for the parent category
        let totalBudgetAmount = budgets
            .filter { $0.parentCategory == budget.parentCategory && $0.subCategory != nil }
            .reduce(0.0) { $0 + $1.allocatedAmount }

        if let parentCategoryIndex = budgets.firstIndex(where: { $0.parentCategory == budget.parentCategory && $0.subCategory == nil }) {
            budgets[parentCategoryIndex].allocatedAmount = totalBudgetAmount
        }

        // Save updated budgets
        saveBudgets(budgets)
    }

    // Deletes a budget
    static func deleteBudget(_ budget: Budget) {
        var budgets = getBudgets()
        budgets.removeAll { $0.parentCategory == budget.parentCategory && $0.subCategory == budget.subCategory }
        
        saveBudgets(budgets)
    }

    // Retrieves a budget for a category or subcategory
    static func getBudget(
        forCategory parentCategory: String,
        subCategory: String? = nil,
        ledgerGroup: String? = nil
    ) -> Budget? {
        return getBudgets().first { budget in
            // Check for matching parentCategory
            guard budget.parentCategory == parentCategory else { return false }

            // Check for matching subCategory, if provided
            if let sub = subCategory {
                guard budget.subCategory == sub else { return false }
            }

            // Check for matching ledgerGroup, if provided
            if let lg = ledgerGroup {
                guard budget.ledgerGroup == lg else { return false }
            }
            return true
        }
    }

    // Retrieves a budget for a specific subcategory
    static func getBudget(forSubcategory subCategory: String) -> Budget? {
        return getBudgets().first { $0.subCategory == subCategory }
    }

    // MARK: - Transactions Management
    // Retrieves all transactions
    static func getTransactions() -> [Transaction] {
        guard let data = UserDefaults.standard.data(forKey: "transactionsData"),
              let transactions = try? JSONDecoder().decode([Transaction].self, from: data) else {
            return []
        }
        return transactions
    }

    // MARK: - Data Clearing
    // Clears all data
    static func clearAllData() {
    // ✅ Clear all stored categories & subcategories
    saveCategories([:])
    saveSubcategoriesByCategory([:])

    // ✅ Explicitly clear all UserDefaults keys related to budgets, transactions, ledger groups, and expenses/income
    UserDefaults.standard.removeObject(forKey: budgetsKey)
    UserDefaults.standard.removeObject(forKey: "transactionsData")
    UserDefaults.standard.removeObject(forKey: "expenseTransactions") // ✅ Clears expenses
    UserDefaults.standard.removeObject(forKey: "incomeTransactions") // ✅ Clears income
    UserDefaults.standard.removeObject(forKey: "ledgerGroups") // ✅ Clears ledger groups


    // ✅ Notify UI to refresh and prevent displaying old data
    NotificationCenter.default.post(name: .categoriesUpdated, object: nil)
    NotificationCenter.default.post(name: .transactionsUpdated, object: nil)
    NotificationCenter.default.post(name: .accountsUpdated, object: nil)

    UserDefaults.standard.synchronize() // ✅ Ensures immediate data removal
    }
}
