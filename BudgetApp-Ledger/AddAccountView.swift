//
//  AddAccountView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/4/25.
//  Updated on 3/27/25 - Unified add/edit logic, ensures newly created/edited accounts appear in AccountsDetailView
//

import SwiftUI

struct AddAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var accountStore: AccountStore
    
    // MARK: - Customizable Properties
    var formBackgroundColor: Color = Color(.systemGray6)
    var fieldLabelColor: Color = .gray
    var fieldFont: Font = .subheadline
    var headerFont: Font = .headline
    var buttonColor: Color = .blue
    
    // MARK: - For Editing
    var accountToEdit: Account? = nil
    
    // MARK: - State Variables
    @State private var accountName: String = ""
    @State private var descriptionText: String = ""
    @State private var accountType: String = "Debit"
    @State private var openingBalance: Double? = nil
    @State private var asOfDate: Date = Date()
    @State private var ledgerGroup: String = ""
    @State private var existingLedgers: [String] = UserDefaults.standard.getLedgers()
    @State private var notes: String = ""
    
    // New Credit-specific fields
    @State private var creditLimit: Double? = nil
    @State private var statementBalance: Double? = nil
    @State private var billingDate: Date = Date()
    @State private var dueDate: Date = Date()
    
    @State private var showConfirmation = false
    @State private var showMissingFieldsAlert = false
    
    /// Called after saving a new or updated account
    var onSave: (Account) -> Void
    
    // MARK: - Init
    init(
        accountToEdit: Account? = nil,
        accountStore: AccountStore,
        onSave: @escaping (Account) -> Void
    ) {
        self.accountToEdit = accountToEdit
        self.accountStore = accountStore
        self.onSave = onSave
        
        // If editing, pre-fill the fields
        if let account = accountToEdit {
            _accountName = State(initialValue: account.name)
            _descriptionText = State(initialValue: account.description)
            _accountType = State(initialValue: account.type)
            _openingBalance = State(initialValue: account.openingBalance)
            _asOfDate = State(initialValue: account.asOfDate)
            _ledgerGroup = State(initialValue: account.ledgerGroup)
            
            // Pre-fill credit-specific fields if the account is Credit
            if account.type == "Credit" {
                _creditLimit = State(initialValue: account.creditLimit)
                _statementBalance = State(initialValue: account.statementBalance)
                _billingDate = State(initialValue: account.billingDate ?? Date())
                _dueDate = State(initialValue: account.dueDate ?? Date())
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Customizable background
                formBackgroundColor
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 10) {
                    Divider().padding(.horizontal)
                    
                    // Row 1: Account Name & Description
                    HStack(spacing: 10) {
                        VStack(alignment: .center) {
                            Text("Account Name")
                                .foregroundColor(fieldLabelColor)
                                .font(fieldFont)
                            TextField("e.g. Checking", text: $accountName)
                                .font(fieldFont)
                                .multilineTextAlignment(.center)
                                .foregroundColor(fieldLabelColor)
                                .padding(.vertical, 7)
                                .padding(.horizontal, 8)
                                .frame(width: 130)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(5)
                        }
                        
                        VStack(alignment: .center) {
                            Text("Description")
                                .foregroundColor(fieldLabelColor)
                                .font(fieldFont)
                            TextField("e.g. Personal account", text: $descriptionText)
                                .font(fieldFont)
                                .multilineTextAlignment(.center)
                                .foregroundColor(fieldLabelColor)
                                .padding(.vertical, 7)
                                .padding(.horizontal, 8)
                                .frame(width: 130)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(5)
                        }
                    }
                    
                    // Row 2: As of Date & Opening Balance (or omitted for Credit accounts)
                    HStack(spacing: 10) {
                        VStack(alignment: .center) {
                            Text("As of Date")
                                .foregroundColor(fieldLabelColor)
                                .font(fieldFont)
                            DatePicker("", selection: $asOfDate, displayedComponents: .date)
                                .labelsHidden()
                                .frame(width: 130)
                        }
                        
                        if accountType != "Credit" {
                            VStack(alignment: .center) {
                                Text("Opening Balance")
                                    .foregroundColor(fieldLabelColor)
                                    .font(fieldFont)
                                TextField("0.00", value: $openingBalance, format: .currency(code: "USD"))
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.gray)
                                    .font(fieldFont)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 8)
                                    .frame(width: 130)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(5)
                            }
                        }
                    }
                    
                    // Credit-specific fields
                    if accountType == "Credit" {
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                VStack(alignment: .center) {
                                    Text("Credit Limit")
                                        .foregroundColor(fieldLabelColor)
                                        .font(fieldFont)
                                    TextField("0.00", value: $creditLimit, format: .currency(code: "USD"))
                                        .keyboardType(.decimalPad)
                                        .foregroundColor(.gray)
                                        .font(fieldFont)
                                        .multilineTextAlignment(.center)
                                        .padding(.vertical, 7)
                                        .padding(.horizontal, 8)
                                        .frame(width: 130)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(5)
                                }
                                VStack(alignment: .center) {
                                    Text("Statement Balance")
                                        .foregroundColor(fieldLabelColor)
                                        .font(fieldFont)
                                    TextField("0.00", value: $statementBalance, format: .currency(code: "USD"))
                                        .keyboardType(.decimalPad)
                                        .foregroundColor(.gray)
                                        .font(fieldFont)
                                        .multilineTextAlignment(.center)
                                        .padding(.vertical, 7)
                                        .padding(.horizontal, 8)
                                        .frame(width: 130)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(5)
                                }
                            }
                            VStack(alignment: .center) {
                                Text("Account Balance")
                                    .foregroundColor(fieldLabelColor)
                                    .font(fieldFont)
                                Text((creditLimit ?? 0) - (statementBalance ?? 0), format: .currency(code: "USD"))
                                    .font(fieldFont)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 8)
                                    .frame(width: 130)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(5)
                            }
                            HStack(spacing: 10) {
                                VStack(alignment: .center) {
                                    Text("Billing Date")
                                        .foregroundColor(fieldLabelColor)
                                        .font(fieldFont)
                                    DatePicker("", selection: $billingDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .frame(width: 130)
                                }
                                VStack(alignment: .center) {
                                    Text("Due Date")
                                        .foregroundColor(fieldLabelColor)
                                        .font(fieldFont)
                                    DatePicker("", selection: $dueDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .frame(width: 130)
                                }
                            }
                        }
                    }
                    
                    // Row 3: Ledger Group & Account Type (menus)
                    HStack(spacing: 10) {
                        VStack(alignment: .center) {
                            Text("Ledger Group")
                                .foregroundColor(fieldLabelColor)
                                .font(fieldFont)
                            Menu {
                                if existingLedgers.isEmpty {
                                    Text("No ledgers available").foregroundColor(.gray)
                                } else {
                                    ForEach(existingLedgers, id: \.self) { ledger in
                                        Button(action: {
                                            ledgerGroup = ledger
                                        }) {
                                            Text(ledger)
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(ledgerGroup.isEmpty ? "Select Ledger" : ledgerGroup)
                                        .foregroundColor(ledgerGroup.isEmpty ? .gray : .primary)
                                        .font(fieldFont)
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 7)
                                .padding(.horizontal, 3)
                                .frame(width: 130)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(5)
                            }
                        }
                        
                        VStack(alignment: .center) {
                            Text("Account Type")
                                .foregroundColor(fieldLabelColor)
                                .font(fieldFont)
                            Menu {
                                Button("Debit") { accountType = "Debit" }
                                Button("Credit") { accountType = "Credit" }
                                Button("Savings") { accountType = "Savings" }
                                Button("Investments") { accountType = "Investments" }
                                Button("Cash") { accountType = "Cash" }
                            } label: {
                                HStack {
                                    Text(accountType)
                                        .foregroundColor(.primary)
                                        .font(fieldFont)
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 7)
                                .padding(.horizontal, 3)
                                .frame(width: 130)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(5)
                            }
                        }
                    }
                    
                    // Row 4: Notes
                    VStack(alignment: .center) {
                        Text("Notes")
                            .foregroundColor(fieldLabelColor)
                            .font(fieldFont)
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(5)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitle(
                accountToEdit == nil ? "Add Account" : "Edit Account",
                displayMode: .inline
            )
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button(accountToEdit == nil ? "Save" : "Update") { saveAccount() }
            )
            .alert("Missing Information", isPresented: $showMissingFieldsAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please fill in all required fields before saving.")
            }
            .alert(
                accountToEdit == nil ? "Account Saved" : "Account Updated",
                isPresented: $showConfirmation
            ) {
                Button("OK") { presentationMode.wrappedValue.dismiss() }
            } message: {
                Text(
                    accountToEdit == nil
                    ? "Account saved successfully"
                    : "Account updated successfully"
                )
            }
        }
    }
    
    // MARK: - Save Account
    private func saveAccount() {
        // For Credit accounts, we expect creditLimit and statementBalance to be provided.
        if accountType == "Credit" {
            guard !accountName.isEmpty,
                  !ledgerGroup.isEmpty
            else {
                showMissingFieldsAlert = true
                return
            }
        } else {
            guard !accountName.isEmpty,
                  !ledgerGroup.isEmpty,
                  let _ = openingBalance
            else {
                showMissingFieldsAlert = true
                return
            }
        }
        
        let accountID = accountToEdit?.id ?? UUID()
        
        let computedBalance: Double = accountType == "Credit"
            ? (statementBalance ?? 0.0)
            : (openingBalance ?? 0.0)
        
        let newAccount = Account(
            id: accountID,
            name: accountName,
            type: accountType,
            description: descriptionText,
            openingBalance: computedBalance,
            asOfDate: asOfDate,
            ledgerGroup: ledgerGroup,
            // Pass credit-specific fields if the account is Credit
            creditLimit: accountType == "Credit" ? (creditLimit ?? 0.0) : nil,
            statementBalance: accountType == "Credit" ? (statementBalance ?? 0.0) : nil,
            billingDate: accountType == "Credit" ? billingDate : nil,
            dueDate: accountType == "Credit" ? dueDate : nil,
            notes: notes
        )
        
        // Fire the onSave closure to update or add in parent
        onSave(newAccount)
        
        // Update or add in AccountStore
        if accountStore.accounts.contains(where: { $0.id == accountID }) {
            accountStore.updateAccount(newAccount)
        } else {
            accountStore.addAccount(newAccount)
        }
        
        // Possibly notify other views
        NotificationCenter.default.post(name: .accountsUpdated, object: nil)
        
        showConfirmation = true
    }
}

struct AddAccountView_Previews: PreviewProvider {
    static var previews: some View {
        AddAccountView(
            accountToEdit: Account(
                id: UUID(),
                name: "Savings",
                type: "Savings",
                description: "Emergency fund",
                openingBalance: 1200.0,
                asOfDate: Date(),
                ledgerGroup: "Personal"
            ),
            accountStore: AccountStore()
        ) { _ in }
    }
}
