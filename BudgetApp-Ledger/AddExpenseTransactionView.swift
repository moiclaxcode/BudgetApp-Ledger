//
//  AddExpenseTransactionView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/8/25.
//  3/14/25 V2.1 - Updated to include ledgerGroup selection in the form
//

import SwiftUI

struct AddExpenseTransactionView: View {
    var ledgerGroup: String
    var isBill: Bool = false // <-- new property
    // Customization properties for fonts and colors
    var labelFont: Font = .subheadline
    var labelColor: Color = .gray
    var fieldFont: Font = .callout
    var fieldColor: Color = .primary
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategory: String = ""
    @State private var selectedSubCategory: String = ""
    @State private var notes: String = ""
    @State private var amount: String = "0.00"
    @State private var date: Date = Date()
    @State private var selectedAccountID: UUID?
    @State private var categories: [String] = []
    @State private var subCategories: [String] = []
    @State private var accounts: [Account] = []
    @State private var showErrorAlert = false
    @State private var payee: String = ""
    @State private var showDeleteAlert = false
    // New state variable for ledger group selection in the form.
    @State private var transactionLedgerGroup: String = ""
    
    var existingTransaction: Transaction? // Holds the existing transaction if editing
    var onSave: (Transaction) -> Void
    
    init(ledgerGroup: String, existingTransaction: Transaction? = nil, onSave: @escaping (Transaction) -> Void) {
        self.ledgerGroup = ledgerGroup
        self.existingTransaction = existingTransaction
        self.onSave = onSave
        
        // Pre-fill data when editing
        _selectedCategory = State(initialValue: existingTransaction?.parentCategory ?? "")
        _selectedSubCategory = State(initialValue: existingTransaction?.subCategory ?? "")
        _notes = State(initialValue: existingTransaction?.description ?? "")
        _amount = State(initialValue: existingTransaction?.amount != nil ? String(format: "%.2f", abs(existingTransaction!.amount)) : "0.00")
        _date = State(initialValue: existingTransaction?.date ?? Date())
        _selectedAccountID = State(initialValue: existingTransaction?.accountID)
        _payee = State(initialValue: existingTransaction?.payee ?? "")
        // Set the ledger group for this transaction from the passed ledgerGroup
        _transactionLedgerGroup = State(initialValue: ledgerGroup)
    }
    
    var body: some View {
        NavigationView {
        ZStack {
            Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)).edgesIgnoringSafeArea(.all)
            
                VStack(spacing: 20) {
                    Divider()// Top Divider for structure
                        .frame(height: 0.5)
                        .background(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                        .padding(.horizontal)
                    
                    // Category & Subcategory Row
                    VStack(alignment: .center, spacing: 5) {
                        Text("Category/Subcategory")
                            .font(.subheadline)
                            .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 10) {
                            Menu {
                                if categories.isEmpty {
                                    Text("No Categories Available").foregroundColor(.gray)
                                } else {
                                    ForEach(categories, id: \.self) { category in
                                        Button(action: {
                                            selectedCategory = category
                                            UserDefaults.standard.set(selectedCategory, forKey: "LastUsedCategory")
                                            loadSubCategories()
                                        }) {
                                            Text(category)
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(selectedCategory.isEmpty ? "Category" : selectedCategory)
                                        .foregroundColor(selectedCategory.isEmpty ? labelColor : fieldColor)
                                        .font(.subheadline)
                                    Image(systemName: "chevron.down")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 10, height: 10)
                                        .foregroundColor(Color.gray)
                                }
                                .frame(width:130)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 3)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(5)
                            }
                            
                            Menu {
                                ForEach(subCategories, id: \.self) { subCategory in
                                    Button(action: {
                                        selectedSubCategory = subCategory
                                        UserDefaults.standard.set(selectedSubCategory, forKey: "LastUsedSubCategory")
                                    }) {
                                        Text(subCategory)
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(selectedSubCategory.isEmpty ? "Subcategory" : selectedSubCategory)
                                        .foregroundColor(selectedSubCategory.isEmpty ? labelColor : fieldColor)
                                        .font(.subheadline)
                                    Image(systemName: "chevron.down")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 10, height: 10)
                                        .foregroundColor(.gray)
                                }
                                .frame(width:130)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 3)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(5)
                            }
                        }
                    }
                    
                    // Date, Amount, and Payee/Account Row
                    VStack(spacing: 5) {
                        HStack(spacing: 10) {
                            VStack {
                                Text(isBill ? "Due on" : "Date")
                                    .font(.subheadline)
                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .font(.subheadline)
                                    .labelsHidden()
                                    .frame(width:130)
                                    .padding(.vertical, 1)
                                    .padding(.horizontal, 3)
                            }
                            VStack {
                                Text("Amount")
                                    .font(.subheadline)
                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                TextField("", text: $amount, onEditingChanged: { isEditing in
                                    if isEditing && amount == "0.00" {
                                        amount = ""
                                    }
                                })
                                .keyboardType(.decimalPad)
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 7)
                                .padding(.horizontal, 8)
                                .frame(width: 130)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(5)
                                .onChange(of: amount) { _, newValue in
                                    amount = newValue.filter { "0123456789.".contains($0) }
                                }
                            }
                        }
                        HStack(spacing: 10) {
                            VStack {
                                Text("Pay From")
                                    .font(.subheadline)
                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                Menu {
                                    ForEach(accounts) { account in
                                        Button(action: {
                                            selectedAccountID = account.id
                                        }) {
                                            Text(account.name)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(selectedAccountID == nil ? "Account" : accounts.first(where: { $0.id == selectedAccountID })?.name ?? "Unknown")
                                            .foregroundColor(selectedAccountID == nil ? labelColor : fieldColor)
                                            .font(.subheadline)
                                            .frame(width:60)
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 1)
                                        Image(systemName: "chevron.down")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 10, height: 10)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 36)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(5)
                                    
                                }
                            }
                            VStack {
                                Text("Payee")
                                    .font(.subheadline)
                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                TextField("", text: $payee)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 8)
                                    .frame(width: 130)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(5)
                        
                            }
                        }
                    }
                    
                    // LedgerGroup Selection Field (New)
                    VStack(alignment: .center, spacing: 5) {
                        Text("Ledger Group")
                            .font(.subheadline)
                            .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                            .multilineTextAlignment(.center)
                        Menu {
                            // Assume you have a function to get available ledger groups.
                            ForEach(UserDefaults.standard.getLedgers(), id: \.self) { ledger in
                                Button(action: {
                                    transactionLedgerGroup = ledger
                                }) {
                                    Text(ledger)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(transactionLedgerGroup.isEmpty ? "Select Ledger Group" : transactionLedgerGroup)
                                    .foregroundColor(transactionLedgerGroup.isEmpty ? labelColor : fieldColor)
                                    .font(.subheadline)
                                    .frame(width:120)
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 3)
                                Image(systemName: "chevron.down")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 10, height: 10)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(5)
                        }
                    }
                    
                    // Notes TextArea
                    VStack(alignment: .center, spacing: 5) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                            .multilineTextAlignment(.center)
                        
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(5)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(existingTransaction == nil ? "Add Expense" : "Edit Expense")
                            .font(.headline) // <- Change font here
                            .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995))) // <- Change color here
                    }
                }
                .navigationBarItems(
                    leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                    trailing: Button("Save") {
                        guard !selectedCategory.isEmpty,
                              !selectedSubCategory.isEmpty,
                              let transactionAmount = Double(amount),
                              transactionAmount > 0 else {
                            showErrorAlert = true
                            return
                        }
                        
                        if let transactionToEdit = existingTransaction {
                            // Update existing transaction
                            var updatedTransaction = transactionToEdit
                            updatedTransaction.parentCategory = selectedCategory
                            updatedTransaction.subCategory = selectedSubCategory
                            updatedTransaction.description = notes
                            updatedTransaction.date = date
                            updatedTransaction.amount = -abs(transactionAmount)
                            updatedTransaction.accountID = selectedAccountID ?? UUID()
                            updatedTransaction.ledgerGroup = transactionLedgerGroup
                            updatedTransaction.payee = payee
                            
                            onSave(updatedTransaction)
                        } else {
                            // Create a new transaction
                            let newTransaction = Transaction(
                                id: UUID(),
                                parentCategory: selectedCategory,
                                subCategory: selectedSubCategory,
                                description: notes,
                                date: date,
                                amount: -abs(transactionAmount),
                                accountID: selectedAccountID ?? UUID(),
                                type: "Expense",
                                ledgerGroup: transactionLedgerGroup,
                                payee: payee
                            )
                            
                            var transactions = UserDefaults.standard.savedTransactions
                            transactions.append(newTransaction)
                            UserDefaults.standard.saveTransactions(transactions)
                            
                            // Save last used account
                            if let accountID = selectedAccountID {
                                UserDefaults.standard.set(accountID.uuidString, forKey: "LastUsedAccountID")
                            }
                        }
                        
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                .alert(isPresented: $showErrorAlert) {
                    Alert(title: Text("Error"), message: Text("Please fill in all fields before saving."), dismissButton: .default(Text("OK")))
                }
                // Overlay for delete button in edit mode
                .overlay(
                    Group {
                        if existingTransaction != nil {
                            Button(action: {
                                showDeleteAlert = true
                            }) {
                                Image(systemName: "trash.circle")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 0.7992290977)))
                                    .padding()
                            }
                        }
                    },
                    alignment: .bottomTrailing
                )
                // Delete confirmation alert
                .alert(isPresented: $showDeleteAlert) {
                    Alert(
                        title: Text("Delete Transaction"),
                        message: Text("Are you sure you want to delete this transaction?"),
                        primaryButton: .destructive(Text("Delete")) {
                            var allTransactions = Array(Set(UserDefaults.standard.savedTransactions))
                            if let transactionToDelete = existingTransaction {
                                allTransactions.removeAll { $0.id == transactionToDelete.id }
                                UserDefaults.standard.saveTransactions(allTransactions)
                            }
                            presentationMode.wrappedValue.dismiss()
                        },
                        secondaryButton: .cancel()
                    )
                }
                .onAppear {
                    loadCategories()
                    loadAccounts()
                    loadLastUsedAccount()
                }
            }
        }
    }
    
    func loadCategories() {
        let categoryData = CategoryStorage.getCategories()
        // Ensure we only load categories for the selected Ledger Group
        categories = categoryData[ledgerGroup] ?? []
        
        if categories.isEmpty {
            selectedCategory = ""
        } else if let lastUsedCategory = UserDefaults.standard.string(forKey: "LastUsedCategory"),
                  categories.contains(lastUsedCategory) {
            selectedCategory = lastUsedCategory
        } else {
            selectedCategory = categories.first!
        }
        
        loadSubCategories() // Ensure subcategories reload properly
    }
    
    func loadSubCategories() {
        let subCategoryData = CategoryStorage.getSubcategoriesByCategory()
        // Collect all subcategories from every category, ensuring uniqueness and sorting
        subCategories = Array(Set(subCategoryData.values.flatMap { $0 })).sorted()
        
        if subCategories.isEmpty {
            selectedSubCategory = ""
        } else if let lastUsedSubCategory = UserDefaults.standard.string(forKey: "LastUsedSubCategory"),
                  subCategories.contains(lastUsedSubCategory) {
            selectedSubCategory = lastUsedSubCategory
        } else {
            selectedSubCategory = subCategories.first!
        }
    }
    
    func loadAccounts() {
        accounts = UserDefaults.standard.getAccounts()
        if selectedAccountID == nil || !accounts.contains(where: { $0.id == selectedAccountID }) {
            selectedAccountID = accounts.first?.id
        }
    }
    
    func loadLastUsedAccount() {
        if let lastUsedIDString = UserDefaults.standard.string(forKey: "LastUsedAccountID") {
            selectedAccountID = UUID(uuidString: lastUsedIDString)
        }
    }
}

//Preview
struct AddExpenseTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        AddExpenseTransactionView(ledgerGroup: "Sample Ledger", onSave: { _ in })
    }
}
