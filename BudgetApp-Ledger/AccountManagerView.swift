//
//  AccountManagerView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR on 3/3/25.
//  3/14/25 V1.0 - Working version (Refactored with ZStack, custom backgrounds, and grouping)
//

import SwiftUI

struct AccountManagerView: View {
    // MARK: - State Variables
    @StateObject private var accountStore = AccountStore()
    @State private var editingAccount: Account?
    @State private var showAddAccountView = false
    @State private var showDeleteConfirmation = false
    @State private var accountToDelete: Account?
    @State private var selectedLedgerGroup: String = "All" // Default: show all accounts
    @State private var existingLedgers: [String] = ["All"] + UserDefaults.standard.getLedgers() // Includes "All" option
    
    // MARK: - Computed Properties
    
    // If "All" is selected, group accounts by ledger group; otherwise, just filter.
    var groupedAccounts: [(group: String, accounts: [Account])] {
        let grouped = Dictionary(grouping: accountStore.accounts) { $0.ledgerGroup }
        return grouped.map { (group: $0.key, accounts: $0.value) }
            .sorted { $0.group < $1.group }
    }
    
    var filteredAccounts: [Account] {
        if selectedLedgerGroup == "All" {
            return accountStore.accounts
        } else {
            return accountStore.accounts.filter { $0.ledgerGroup == selectedLedgerGroup }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main content: if "All" is selected, group by ledger; else, use filtered list.
                    if selectedLedgerGroup == "All" {
                        List {
                            ForEach(groupedAccounts, id: \.group) { group in
                                Section(header:
                                    Text(group.group)
                                    .font(.caption2)
                                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                ) {
                                    ForEach(group.accounts) { account in
                                        accountRow(account)
                                    }
                                    .onMove(perform: moveAccount)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        .scrollContentBackground(.hidden)
                        .background(Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)))
                    } else {
                        List {
                            ForEach(filteredAccounts) { account in
                                accountRow(account)
                            }
                            .onMove(perform: moveAccount)
                        }
                        .listStyle(InsetGroupedListStyle())
                        .scrollContentBackground(.hidden)
                        .background(Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)))
                    }
                    
                    // Divider at the bottom of the list
                    Divider()
                }
                .padding(.bottom, 50) // Leave space for the floating plus button
                
                // Floating Plus Button at the bottom-right corner above the divider
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // This triggers new account creation
                            showAddAccountView = true
                        }) {
                            Image(systemName: "plus.circle")
                                .imageScale(.large)
                                .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 60)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Leading: Ledger Group Picker
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Ledger Group", selection: $selectedLedgerGroup) {
                        ForEach(existingLedgers, id: \.self) { ledger in
                            Text(ledger).tag(ledger)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                // Principal: Centered Header
                ToolbarItem(placement: .principal) {
                    Text("Account Manager")
                        .font(.headline)
                        .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                }
            }
            .onAppear {
                refreshLedgers()
            }
            .onReceive(NotificationCenter.default.publisher(for: .accountsUpdated)) { _ in
                // No need to refresh accounts here
            }
            // Replace the old showAddAccountView sheet with an item-based approach:
            .sheet(item: $editingAccount, onDismiss: {
                // Clear editingAccount after dismiss
                editingAccount = nil
            }) { account in
                // If 'account' is non-nil, we're editing that account
                AddAccountView(accountToEdit: account, accountStore: accountStore) { updatedOrNewAccount in
                    accountStore.updateAccount(updatedOrNewAccount)
                    refreshLedgers()
                    NotificationCenter.default.post(name: .accountsUpdated, object: nil)
                }
            }
            // Separate sheet for new accounts
            .sheet(isPresented: $showAddAccountView) {
                // In 'new' mode, we pass nil to AddAccountView.
                AddAccountView(accountToEdit: nil, accountStore: accountStore) { newAccount in
                    accountStore.addAccount(newAccount)
                    refreshLedgers()
                    NotificationCenter.default.post(name: .accountsUpdated, object: nil)
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Account"),
                    message: Text("Are you sure you want to delete this account?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let accountToDelete = accountToDelete {
                            accountStore.deleteAccount(accountToDelete)
                            refreshLedgers()
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    // MARK: - Account Row
    private func accountRow(_ account: Account) -> some View {
        HStack {
            Text(account.name)
                .font(.caption)
                .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
            Text(" - \(account.ledgerGroup)")
                .font(.caption2)
                .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
            Spacer()
            Menu {
                Button("Edit") {
                    editingAccount = account
                }
                Button("Delete", role: .destructive, action: {
                    accountToDelete = account
                    showDeleteConfirmation = true
                })
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                    .padding(.leading, 8)
            }
        }
        .padding(.vertical, 6)
    }
    
    private func moveAccount(from source: IndexSet, to destination: Int) {
        accountStore.accounts.move(fromOffsets: source, toOffset: destination)
        UserDefaults.standard.saveAccounts(accountStore.accounts)
    }
    
    private func refreshLedgers() {
        existingLedgers = ["All"] + UserDefaults.standard.getLedgers()
    }
}

struct AccountManagerView_Previews: PreviewProvider {
    static var previews: some View {
        AccountManagerView()
    }
}
