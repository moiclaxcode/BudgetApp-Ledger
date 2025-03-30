//
//  Account.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/4/25.
//  3/14/25 V1.0 - Working File Usually no changes are need to this view.

import Foundation

struct Account: Identifiable, Codable, Hashable { // ✅ Added Hashable
    var id: UUID
    var name: String
    var type: String // ✅ Re-added type for grouping
    var description: String // ✅ Preserved description for UI
    var openingBalance: Double
    var asOfDate: Date
    var ledgerGroup: String

    init(id: UUID = UUID(), name: String, type: String, description: String, openingBalance: Double, asOfDate: Date, ledgerGroup: String) {
        self.id = id
        self.name = name
        self.type = type // ✅ Needed for grouping in AccountManagerView
        self.description = description
        self.openingBalance = openingBalance
        self.asOfDate = asOfDate
        self.ledgerGroup = ledgerGroup
    }

    // ✅ Conforming to Hashable
    static func == (lhs: Account, rhs: Account) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
