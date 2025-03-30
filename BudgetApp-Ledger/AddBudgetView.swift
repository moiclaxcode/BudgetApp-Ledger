//
//  AddBudgetView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/4/25.
//  3/11/25 V1.0 - Working version

import SwiftUI

struct AddBudgetView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var parentCategory: String = "" // Updated variable name
    @State private var description: String = ""
    @State private var budgetType: String = "Expense"
    @State private var budgetAmount: Double? = nil
    @State private var ledgerGroup: String = ""
    @State private var existingLedgers: [String] = UserDefaults.standard.getLedgers()
    @State private var budgetCycle: String = "Monthly"
    @State private var startDate: Date = Date()
    @State private var showConfirmation = false
    @State private var showMissingFieldsAlert = false
    @State private var budgetSaved = false // ✅ Used to prevent premature dismissal

    let budgetCycles = ["Daily", "Weekly", "Every 2 Weeks", "Every 4 Weeks", "Semimonthly", "Monthly", "Every 2 Months", "Every 3 Months", "Every 4 Months", "Every 6 Months", "Yearly"]

    var onSave: (Budget) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Budget Details")) {
                    TextField("Parent Category", text: $parentCategory) // Updated reference

                    TextField("Description", text: $description)

                    Picker("Type", selection: $budgetType) {
                        Text("Expense").tag("Expense")
                        Text("Income").tag("Income")
                    }
                    .pickerStyle(MenuPickerStyle())

                    TextField("Budget Amount", value: $budgetAmount, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                }

                // ✅ Ledger Picker Section
                Section(header: Text("Ledger Group")) {
                    Picker("Select Ledger", selection: $ledgerGroup) {
                        ForEach(existingLedgers, id: \.self) { ledger in
                            Text(ledger).tag(ledger)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    if existingLedgers.isEmpty {
                        Text("No ledgers available. Please add a ledger first.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                // ✅ Budget Cycle Picker
                Section(header: Text("Budget Cycle")) {
                    Picker("Select Budget Cycle", selection: $budgetCycle) {
                        ForEach(budgetCycles, id: \.self) { cycle in
                            Text(cycle).tag(cycle)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                // ✅ Start Date Picker
                Section(header: Text("Start Date")) {
                    DatePicker("Select Start Date", selection: $startDate, displayedComponents: .date)
                }
            }
            .navigationBarTitle("Add Budget", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") {
                    saveBudget()
                }
            )
            .alert(isPresented: $showConfirmation) { // ✅ FIXED: Now properly shows confirmation before dismissing
                Alert(
                    title: Text("Success"),
                    message: Text("Budget saved successfully"),
                    dismissButton: .default(Text("OK")) {
                        budgetSaved = true // ✅ Marks budget as saved
                        presentationMode.wrappedValue.dismiss() // ✅ Only dismisses after alert is acknowledged
                    }
                )
            }
            .alert(isPresented: $showMissingFieldsAlert) {
                Alert(title: Text("Missing Information"), message: Text("Please fill in all required fields before saving."), dismissButton: .default(Text("OK")))
            }
        }
        .onDisappear {
            if !budgetSaved {
                showConfirmation = false // ✅ Ensures confirmation resets
            }
        }
    }

    private func saveBudget() {
        guard !parentCategory.isEmpty, !ledgerGroup.isEmpty, let amount = budgetAmount else { // Updated reference
            showMissingFieldsAlert = true
            return
        }

        let newBudget = Budget(
            id: UUID(),
            parentCategory: parentCategory, // Updated reference
            description: description,
            type: budgetType,
            budget: amount,
            ledgerGroup: ledgerGroup,
            budgetCycle: budgetCycle,
            startDate: startDate
        )

        onSave(newBudget)

        // ✅ Trigger the confirmation alert before dismissing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showConfirmation = true
        }
    }
}
