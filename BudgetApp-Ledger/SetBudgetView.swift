//
//  SetBudgetView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/11/25.
//  3/14/25 V1.1 - Refactored to support both add and edit in a ZStack layout
//

import SwiftUI

struct SetBudgetView: View {
    var budget: Budget
    var onSave: (() -> Void)?
    
    // MARK: - State Variables
    @State private var budgetAmount: String = "0.00"
    @State private var selectedCycle: String = "Monthly"
    @State private var startDate: Date = Date()
    @State private var showConfirmation = false
    @State private var isEditing: Bool
    @Environment(\.presentationMode) private var presentationMode

    // MARK: - Customization Variables
    var backgroundColor: Color = Color(UIColor.systemGray6)
    var headerFont: Font = .headline
    var subHeaderFont: Font = .subheadline
    var bodyFont: Font = .body
    var navButtonColor: Color = .blue
    
    let budgetCycles = ["Monthly", "Every 2 months", "Every 3 months", "Every 4 months", "Every 6 months", "Yearly", "Weekly", "Every 2 weeks", "Every 4 weeks", "Daily", "Semimonthly"]
    
    // MARK: - Initializer
    init(budget: Budget, onSave: (() -> Void)? = nil) {
        self.budget = budget
        self.onSave = onSave
        // If the budget's allocatedAmount is greater than 0, we consider it an edit.
        _budgetAmount = State(initialValue: budget.allocatedAmount > 0 ? String(format: "%.2f", budget.allocatedAmount) : "0.00")
        _isEditing = State(initialValue: budget.allocatedAmount > 0)
        _selectedCycle = State(initialValue: budget.budgetCycle)
        _startDate = State(initialValue: budget.startDate)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1))
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Divider() // Top divider for structure
                    
                    // Display Subcategory (read-only)
                    VStack(spacing: 5) {
                        Text("Subcategory")
                            .font(subHeaderFont)
                            .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                        Text(budget.subCategory ?? "No Subcategory")
                            .font(bodyFont)
                            .bold()
                    }
                    
                    // Input fields for amount and cycle
                    VStack(spacing: 20) {
                        HStack(spacing: 40) {
                            VStack {
                                Text("Amount")
                                    .font(.subheadline)
                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                TextField("", text: $budgetAmount)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.gray)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 8)
                                    .frame(width: 130)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(5)
                                    .onChange(of: budgetAmount) { _, newValue in
                                        let filtered = newValue.filter { "0123456789.".contains($0) }
                                        if filtered != newValue {
                                            budgetAmount = filtered
                                        }
                                    }
                            }
                            
                            VStack {
                                Text("Budget Cycle")
                                    .font(subHeaderFont)
                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                Menu {
                                    ForEach(budgetCycles, id: \.self) { cycle in
                                        Button(action: {
                                            selectedCycle = cycle
                                        }) {
                                            Text(cycle)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedCycle)
                                            .font(.subheadline)
                                            .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                        Image(systemName: "chevron.down")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 10, height: 10)
                                            .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                    }
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 8)
                                    .frame(width: 130)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(5)
                                }
                            }
                        }
                    }
                    
                    // Date picker for cycle start date
                    VStack(spacing: 5) {
                        Text("Cycle Start Date")
                            .font(subHeaderFont)
                            .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                            .frame(width: 140, height: 40)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            // Header Title
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(isEditing ? "Update Budget" : "Set Budget")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                }
            }
            .navigationBarItems(trailing:
                Button(isEditing ? "Update" : "Save") {
                    saveBudget()
                    onSave?()
                }
                .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                .bold()
            )
            .alert(isPresented: $showConfirmation) {
                Alert(title: Text("Budget Saved"),
                      message: Text("Your budget has been successfully saved."),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    // MARK: - Save Budget Function
    private func saveBudget() {
        guard let amount = Double(budgetAmount), amount >= 0 else {
            print("Invalid budget amount: \(budgetAmount)")
            return
        }
        var updatedBudget = budget
        updatedBudget.allocatedAmount = amount
        updatedBudget.budgetCycle = selectedCycle
        updatedBudget.startDate = startDate
        
        // Save or update the budget in storage.
        CategoryStorage.saveBudget(updatedBudget)
        
        showConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
struct SetBudgetView_Previews: PreviewProvider {
    static var previews: some View {
        SetBudgetView(budget: Budget(
            id: UUID(),
            parentCategory: "Example Category",
            subCategory: "Preview",
            description: "Sample budget description",
            type: "expense",
            budget: 0.0,
            budgetCycle: "Monthly",
            startDate: Date()
        ))
    }
}
