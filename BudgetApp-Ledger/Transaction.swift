//
//  Transaction.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/5/25.
//  Last updated on 3/10/25. Key changes: Fixed initializer to support subCategory.
//  3/11/25 V1.0 - Working version

import Foundation

enum TransactionType: String, Codable {
    case income
    case expense
    case transfer
}

struct Transaction: Identifiable, Codable, Hashable { // ✅ Added Hashable
    var id: UUID
    var parentCategory: String // Renamed from category to parentCategory
    var subCategory: String? // ✅ Added subcategory support
    var description: String
    var date: Date
    var amount: Double
    var accountID: UUID
    var type: TransactionType // Updated type to TransactionType
    var isOpeningBalance: Bool // ✅ Identifies opening balance transactions
    var ledgerGroup: String // ✅ Added Ledger Group
    var payee: String? // ✅ Added payee property
    var notes: String? // ✅ Added notes field for income transactions
    
    // New properties for transfers:
    var fromAccountID: UUID?
    var toAccountID: UUID?
    
    init(
        id: UUID = UUID(),
        parentCategory: String,
        subCategory: String? = nil,
        description: String,
        date: Date,
        amount: Double,
        accountID: UUID,
        type: TransactionType,
        isOpeningBalance: Bool = false,
        ledgerGroup: String = "General",
        payee: String? = nil,
        notes: String? = nil,
        fromAccountID: UUID? = nil,
        toAccountID: UUID? = nil
    ) {
        self.id = id
        self.parentCategory = parentCategory // Updated reference
        self.subCategory = subCategory // ✅ Fixed missing assignment
        self.description = description
        self.date = date
        self.amount = amount
        self.accountID = accountID
        self.type = type // Updated assignment to TransactionType
        self.isOpeningBalance = isOpeningBalance // ✅ Default to false unless specified
        self.ledgerGroup = ledgerGroup // ✅ Added to store transaction ledger group
        self.payee = payee // ✅ Added payee field
        self.notes = notes // ✅ Included notes in initialization
        self.fromAccountID = fromAccountID
        self.toAccountID = toAccountID
    }
}

// ✅ Helper to format dates properly
extension Transaction {
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
