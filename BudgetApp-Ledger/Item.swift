//
//  Item.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/3/25.
//  3/11/25 V1.0 - Working version (might need to delete this view)

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
