//
//  EditSetBudgetView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/11/25.
//  3/14/25 V1.1 - Refined UI, removed Ledger Group Picker
//

import SwiftUI

struct EditSetBudgetView: View {
    @State private var budget: Budget
    @State private var budgetAmount: String
    @State private var selectedCycle: String
    @State private var startDate: Date
    @State private var selectedSubCategory: String
    @State private var availableSubCategories: [String] = []
    @State private var showConfirmation = false
    @Environment(\.presentationMode) private var presentationMode
    
    let budgetCycles = ["Monthly", "Every 2 months", "Every 3 months", "Every 4 months", "Every 6 months", "Yearly", "Weekly", "Every 2 weeks", "Every 4 weeks", "Daily", "Semimonthly"]

    init(budget: Budget) {
        _budget = State(initialValue: budget)
        _budgetAmount = State(initialValue: String(format: "%.2f", budget.allocatedAmount))
        _selectedCycle = State(initialValue: budget.budgetCycle)
        _startDate = State(initialValue: budget.startDate)
        _selectedSubCategory = State(initialValue: budget.subCategory ?? "")
        _availableSubCategories = State(initialValue: CategoryStorage.getSubcategories(forCategory: budget.parentCategory))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) { // Adjust spacing for better alignment
                Divider() // Added divider at the top for structure

                VStack(spacing: 5) {
                    Text("Subcategory")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text(selectedSubCategory.isEmpty ? "No Subcategory" : selectedSubCategory)
                        .font(.body)
                        .bold()
                }
                
                VStack(spacing: 20) {
                    HStack(spacing: 40) { // Increased spacing for symmetry
                        VStack {
                            Text("Amount")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            TextField("", text: $budgetAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .multilineTextAlignment(.center)
                                .frame(width: 120, height: 40)
                        }

                        VStack {
                            Text("Budget Cycle")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Picker("", selection: $selectedCycle) {
                                ForEach(budgetCycles, id: \.self) { cycle in
                                    Text(cycle)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 140, height: 40)
                        }
                    }
                }

                VStack(spacing: 5) {
                    Text("Cycle Start Date")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(width: 140, height: 40)
                }

                Spacer()
            }
            .padding()
            .navigationBarTitle("Edit Set Budget", displayMode: .inline)
            .navigationBarItems(trailing:
                Button("Save") {
                    saveEdits()
                }
                .foregroundColor(.blue)
                .bold()
            )
            .alert(isPresented: $showConfirmation) {
                Alert(title: Text("Changes Saved"), message: Text("Your budget updates have been successfully saved."), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func saveEdits() {
        guard let amount = Double(budgetAmount) else { return }

        budget.allocatedAmount = amount
        budget.budgetCycle = selectedCycle
        budget.startDate = startDate
        budget.subCategory = selectedSubCategory.isEmpty ? nil : selectedSubCategory

        CategoryStorage.saveBudget(budget)
        showConfirmation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
