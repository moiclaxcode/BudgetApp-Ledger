//
//  CategoryStore.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/29/25.

import Foundation
import SwiftUI

class CategoryStore: ObservableObject {
    // MARK: - State
    let ledgerGroup: String

    @Published var categories: [String] = []
    @Published var subcategories: [String] = []
    @Published var budgets: [Budget] = []
    @Published var transactions: [Transaction] = []

    // MARK: - Init
    init(ledgerGroup: String) {
        self.ledgerGroup = ledgerGroup
        loadCategories()
        loadBudgets()
        loadTransactions()
    }

    // MARK: - Category Management
    func loadCategories() {
        categories = CategoryStorage.getCategoriesByLedgerGroup(ledgerGroup)
    }

    func addCategory(_ name: String) {
        CategoryStorage.addCategory(name, toLedgerGroup: ledgerGroup)
        loadCategories()
    }

    func renameCategory(at index: Int, to newName: String) {
        guard categories.indices.contains(index) else { return }
        let oldName = categories[index]
        CategoryStorage.renameCategory(from: oldName, to: newName, for: ledgerGroup)
        loadCategories()
    }

    func deleteCategory(at index: Int) {
        guard categories.indices.contains(index) else { return }
        let name = categories[index]
        CategoryStorage.deleteCategory(name, fromLedgerGroup: ledgerGroup)
        loadCategories()
    }

    func moveCategory(fromOffsets source: IndexSet, toOffset destination: Int) {
        CategoryStorage.moveCategory(fromOffsets: source, toOffset: destination, for: ledgerGroup)
        loadCategories()
    }

    // MARK: - Subcategory Management
    func loadSubcategories(for category: String) {
        subcategories = CategoryStorage.getSubcategories(forCategory: category)
    }
    
    func getSubcategories(for category: String) -> [String] {
        return CategoryStorage.getSubcategories(forCategory: category)
    }

    func addSubcategory(_ name: String, to category: String) {
        CategoryStorage.addSubcategory(name, toCategory: category)
        loadSubcategories(for: category)
    }

    func deleteSubcategory(_ name: String, from category: String) {
        CategoryStorage.deleteSubcategory(name, fromCategory: category)
        loadSubcategories(for: category)
    }
    
    func saveSubcategories(for category: String, subcategories: [String]) {
        CategoryStorage.saveSubcategories(forCategory: category, subcategories: subcategories)
    }

    // MARK: - Budget Management
    func loadBudgets() {
        budgets = CategoryStorage.getBudgets().filter { $0.ledgerGroup == ledgerGroup }
    }

    func saveBudget(_ budget: Budget) {
        CategoryStorage.saveBudget(budget)
        loadBudgets()
    }

    func getBudget(for subcategory: String) -> Budget? {
        return budgets.first { $0.subCategory == subcategory }
    }

    func totalBudget(for category: String) -> Double {
        budgets
            .filter { $0.parentCategory == category }
            .map { $0.allocatedAmount }
            .reduce(0, +)
    }

    func totalBudget(for category: String, subcategory: String) -> Double {
        budgets
            .filter { $0.parentCategory == category && $0.subCategory == subcategory }
            .map { $0.allocatedAmount }
            .reduce(0, +)
    }

    // MARK: - Transaction Tracking
    func loadTransactions() {
        transactions = UserDefaults.standard.getTransactions(for: ledgerGroup)
    }

    func totalSpent(for category: String) -> Double {
        transactions
            .filter { $0.parentCategory == category && $0.type == .expense }
            .map { $0.amount }
            .reduce(0, +)
    }

    func totalSpent(for category: String, subcategory: String) -> Double {
        transactions
            .filter { $0.parentCategory == category && $0.subCategory == subcategory && $0.type == .expense }
            .map { $0.amount }
            .reduce(0, +)
    }
}
