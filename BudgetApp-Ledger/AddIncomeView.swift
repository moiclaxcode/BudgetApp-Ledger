//
//  AddIncomeView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/18/25.
//

import SwiftUI

struct AddIncomeView: View {
    @StateObject private var transactionStore = TransactionStore()
    
    var ledgerGroup: String
    var existingTransaction: Transaction? = nil
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var description: String = ""
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var selectedAccountID: UUID?
    @State private var notes: String = ""
    @State private var accounts: [Account] = UserDefaults.standard.getAccounts()
    
    // New state variable for ledger group selection in the form.
    @State private var transactionLedgerGroup: String = ""
    
    // New state variable for delete confirmation
    @State private var showDeleteAlert: Bool = false
    
    // MARK: - Initializer
    init(ledgerGroup: String, existingTransaction: Transaction? = nil) {
        self.ledgerGroup = ledgerGroup
        self.existingTransaction = existingTransaction
        
        if let transaction = existingTransaction {
            _description = State(initialValue: transaction.description)
            _amount = State(initialValue: String(format: "%.2f", abs(transaction.amount)))
            _date = State(initialValue: transaction.date)
            _selectedAccountID = State(initialValue: transaction.accountID)
            _notes = State(initialValue: transaction.notes ?? "")
            _transactionLedgerGroup = State(initialValue: transaction.ledgerGroup)
        } else {
            // For new transactions, default to the ledger group passed in from DashboardView
            _transactionLedgerGroup = State(initialValue: ledgerGroup)
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                Color(#colorLiteral(red: 0.968627451,
                                    green: 0.968627451,
                                    blue: 0.968627451,
                                    alpha: 1))
                .edgesIgnoringSafeArea(.all)
                
                mainFormContent
                
                if existingTransaction != nil {
                    deleteButtonOverlay
                }
            }
            // Navigation items
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: saveButton
            )
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(existingTransaction == nil ? "Add Income" : "Edit Income")
                        .font(.headline)
                        .foregroundColor(
                            Color(#colorLiteral(
                                red: 0.298,
                                green: 0.3059,
                                blue: 0.6078,
                                alpha: 0.7995
                            ))
                        )
                }
            }
            // Delete confirmation alert
            .alert("Delete Transaction", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let transactionToDelete = existingTransaction {
                        var savedTransactions = UserDefaults.standard.getTransactions(for: transactionToDelete.ledgerGroup)
                        savedTransactions.removeAll { $0.id == transactionToDelete.id }
                        UserDefaults.standard.saveTransactions(savedTransactions)
                        
                        // Also remove from the income list
                        var savedIncome = UserDefaults.standard.getIncomeTransactions()
                        savedIncome.removeAll { $0.id == transactionToDelete.id }
                        UserDefaults.standard.saveIncomeTransactions(savedIncome)
                        
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this transaction?")
            }
        }
    }
    
    // MARK: - Main Form Content
    private var mainFormContent: some View {
        VStack(spacing: 20) {
            Divider() // Top Divider for structure
            
            // Description and Amount side-by-side
            HStack(spacing: 10) {
                descriptionField
                amountField
            }
            
            // Add Income to / Date
            HStack(spacing: 20) {
                incomeAccountField
                dateField
            }
            
            // Ledger Group
            ledgerGroupField
            
            // Notes
            notesField
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Subviews
    private var descriptionField: some View {
        VStack(alignment: .center) {
            Text("Description")
                .font(.subheadline)
                .foregroundColor(.gray)
            TextField("e.g Paycheck", text: $description)
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .frame(width: 130)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
        }
    }
    
    private var amountField: some View {
        VStack(alignment: .center) {
            Text("Amount")
                .font(.subheadline)
                .foregroundColor(.gray)
            TextField("0.00", text: $amount)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .frame(width: 130)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
                .onChange(of: amount) { _, newValue in
                    amount = newValue.filter { "0123456789.".contains($0) }
                }
        }
    }
    
    private var incomeAccountField: some View {
        VStack(alignment: .center) {
            Text("Add Income to")
                .font(.subheadline)
                .foregroundColor(.gray)
            Menu {
                ForEach(accounts) { account in
                    Button(action: {
                        selectedAccountID = account.id
                    }) {
                        Text(account.name)
                    }
                }
            } label: {
                HStack {
                    Text(selectedAccountID == nil
                         ? "Account"
                         : accounts.first(where: { $0.id == selectedAccountID })?.name ?? "Unknown")
                        .foregroundColor(selectedAccountID == nil ? .gray : .primary)
                        .font(.subheadline)
                        .frame(width: 60)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 1)
                    Image(systemName: "chevron.down")
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 25)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
            }
        }
    }
    
    private var dateField: some View {
        VStack(alignment: .center) {
            Text("Date")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.vertical, 1)
            DatePicker("", selection: $date, displayedComponents: .date)
                .font(.subheadline)
                .labelsHidden()
                .frame(width:120)
                .padding(.vertical, 1)
                .padding(.horizontal, 3)
        }
    }
    
    private var ledgerGroupField: some View {
        VStack(alignment: .center) {
            Text("Ledger Group")
                .font(.subheadline)
                .foregroundColor(.gray)
            Menu {
                ForEach(UserDefaults.standard.getLedgers(), id: \.self) { ledger in
                    Button(action: {
                        transactionLedgerGroup = ledger
                    }) {
                        Text(ledger)
                    }
                }
            } label: {
                HStack (alignment: .center){
                    Text(transactionLedgerGroup.isEmpty
                         ? "Select Ledger Group"
                         : transactionLedgerGroup)
                        .foregroundColor(transactionLedgerGroup.isEmpty ? .gray : .primary)
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
    }
    
    private var notesField: some View {
        VStack(alignment: .center) {
            Text("Notes")
                .font(.subheadline)
                .foregroundColor(.gray)
            TextEditor(text: $notes)
                .frame(height: 100)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(5)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Delete Button Overlay
    private var deleteButtonOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
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
        }
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button("Save") {
            saveTransaction()
        }
        .disabled(amount.isEmpty || selectedAccountID == nil)
    }
    
    // MARK: - Save Transaction Logic
    private func saveTransaction() {
        guard let transactionAmount = Double(amount),
              let selectedAccountID = selectedAccountID
        else { return }
        
        let newTransaction = Transaction(
            id: existingTransaction?.id ?? UUID(),
            parentCategory: "Income",
            subCategory: nil,
            description: description,
            date: date,
            amount: abs(transactionAmount),
            accountID: selectedAccountID,
            type: "Income",
            ledgerGroup: transactionLedgerGroup,
            notes: notes
        )
        
        transactionStore.save(newTransaction, for: selectedAccountID)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Preview
struct AddIncomeView_Previews: PreviewProvider {
    static var previews: some View {
        AddIncomeView(
            ledgerGroup: "Sample Ledger"
        )
    }
}
