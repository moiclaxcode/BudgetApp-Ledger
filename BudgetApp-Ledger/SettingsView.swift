//
//  SettingsView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/3/25.
//  3/14/25 V1.0 - Working version

import SwiftUI


struct SettingsView: View {
    @State private var showLedgerManager = false
    @State private var showAccountManager = false
    @State private var showResetConfirmation = false

    var body: some View {
        ZStack {
            // Background customization
            Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)) // #F7F7F7 Background
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Custom header
                ZStack {
                    Text("Settings")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                // Custom styled list
                ZStack {
                    Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)) // or your preferred background color
                    List {
                        Section {
                            Button(action: {
                                showLedgerManager = true
                            }) {
                                HStack {
                                    Image(systemName: "folder")
                                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                    Text("Ledger Manager")
                                        .font(.subheadline)
                                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                }
                                .padding(.vertical, 8)
                            }
                            

                            Button(action: {
                                showAccountManager = true
                            }) {
                                HStack {
                                    Image(systemName: "person.crop.circle")
                                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                    Text("Account Manager")
                                        .font(.subheadline)
                                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                }
                                .padding(.vertical, 8)
                            }
                            

                            Button(action: {
                                showResetConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                    Text("Reset App")
                                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                        .font(.subheadline)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                            .alert(isPresented: $showResetConfirmation) {
                                Alert(
                                    title: Text("Reset App?"),
                                    message: Text("This will delete all data and restore defaults. This action cannot be undone."),
                                    primaryButton: .destructive(Text("Reset")) {
                                        UserDefaults.standard.resetAppData()
                                        showResetConfirmation = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                                        }
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                            
                        }
                    }
                    .scrollContentBackground(.hidden) // Hides UITableView default background
                    .background(Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1))) // Custom background behind list rows
                    .listStyle(InsetGroupedListStyle())
                }
                 
            }

            // Sheet Modals
            .sheet(isPresented: $showLedgerManager) {
                LedgerManagerView()
            }
            .sheet(isPresented: $showAccountManager) {
                AccountManagerView()
            }
        }
    }
}
//Preview
struct SettingsView_Previews: PreviewProvider {
static var previews: some View {
    SettingsView()
}
}
