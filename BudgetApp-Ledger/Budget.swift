//
//  Budget.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/4/25.
//  3/14/25 V1.0 - Working version

import Foundation

struct Budget: Identifiable, Codable, Hashable {
    var id: UUID
    var parentCategory: String  // Updated from categoryName to parentCategory
    var subCategory: String?
    var description: String
    var type: String
    var allocatedAmount: Double
    var spentAmount: Double
    var ledgerGroup: String?
    var budgetCycle: String
    var startDate: Date

    init(id: UUID = UUID(), parentCategory: String, subCategory: String? = nil, description: String, type: String, budget: Double, ledgerGroup: String? = nil, budgetCycle: String, startDate: Date) {
        self.id = id
        self.parentCategory = parentCategory // Updated reference
        self.subCategory = subCategory
        self.description = description
        self.type = type
        self.allocatedAmount = budget
        self.spentAmount = 0.0
        self.ledgerGroup = ledgerGroup
        self.budgetCycle = budgetCycle
        self.startDate = startDate
    }
}
