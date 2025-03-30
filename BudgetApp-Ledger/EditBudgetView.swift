//
//  EditBudgetView.swift
//  BudgetApp-Ledger
//  Updated on 3/14/25 - Removed Ledger Picker and Category Name
//

import SwiftUI

struct EditBudgetView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var budgetAmount: Double
    @State private var budgetCycle: String
    @State private var startDate: Date
    @State private var showConfirmation = false
    
    let budgetCycles = ["Daily", "Weekly", "Every 2 Weeks", "Every 4 Weeks", "Semimonthly", "Monthly", "Every 2 Months", "Every 3 Months", "Every 4 Months", "Every 6 Months", "Yearly"]
    
    var onSave: (Budget) -> Void
    var budget: Budget
    
    init(budget: Budget, onSave: @escaping (Budget) -> Void) {
        self.budget = budget
        self.onSave = onSave
        _budgetAmount = State(initialValue: budget.allocatedAmount)
        _budgetCycle = State(initialValue: budget.budgetCycle)
        _startDate = State(initialValue: budget.startDate)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Subcategory")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(budget.subCategory ?? "No Subcategory")
                    .font(.body)
                    .padding(.horizontal)

                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Amount")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        TextField("", value: $budgetAmount, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                    }

                    VStack(alignment: .leading) {
                        Text("Budget Cycle")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Picker("", selection: $budgetCycle) {
                            ForEach(budgetCycles, id: \.self) { cycle in
                                Text(cycle)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 140)
                    }
                }

                VStack(alignment: .leading) {
                    Text("Cycle Start Date")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    DatePicker("", selection: $startDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(width: 140)
                }

                Spacer()
            }
            .padding()
            .navigationBarTitle("Edit Budget", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") {
                    saveBudget()
                }
            )
            .alert(isPresented: $showConfirmation) {
                Alert(title: Text("Success"), message: Text("Budget updated successfully"), dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
    }
    
    private func saveBudget() {
        let updatedBudget = Budget(
            id: budget.id,
            parentCategory: budget.parentCategory, // Updated reference
            subCategory: budget.subCategory, // Subcategory remains the same
            description: budget.description, // Retain existing description if needed
            type: budget.type,
            budget: budgetAmount,
            ledgerGroup: budget.ledgerGroup,
            budgetCycle: budgetCycle,
            startDate: startDate
        )
        
        onSave(updatedBudget)
        showConfirmation = true
    }
}
