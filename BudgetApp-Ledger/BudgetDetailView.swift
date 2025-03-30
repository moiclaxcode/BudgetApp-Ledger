//
//  BudgetDetailView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/5/25.
//  3/14/25 V1.0 - Working version

import SwiftUI

struct BudgetDetailView: View {
    var cardType: String
    var ledgerGroup: String

    var body: some View {
        NavigationView {
            VStack {
                Text("\(cardType) Details")
                    .font(.title)
                    .bold()
                    .padding()

                Text("Ledger Group: \(ledgerGroup)")
                    .foregroundColor(.gray)

                Spacer()
            }
            .navigationBarTitle("\(cardType) Details", displayMode: .inline)
            .padding()
        }
    }
}

