//
//  BudgetCard.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/3/25.
//  3/14/25 V1.0 - Working version

import SwiftUI

struct BudgetCard: View {
    var title: String
    var amount: String
    var color: Color

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            Text(amount)
                .font(.title2)
                .bold()
                .foregroundColor(color)
        }
        .frame(width: 150, height: 80) // Adjusted size
        .background(Color(.systemGray5))
        .cornerRadius(12)
    }
}
