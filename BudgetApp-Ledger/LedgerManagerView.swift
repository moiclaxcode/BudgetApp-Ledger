//
//  LedgerManagerView.swift
//  BudgetApp-Ledger
//
//  Created by HECTOR  on 3/3/25.
//  3/11/25 V1.0 - Working version

import SwiftUI

struct LedgerManagerView: View {
    @State private var ledgers: [String] = UserDefaults.standard.stringArray(forKey: "ledgers") ?? []
    @State private var newLedgerName: String = ""
    @State private var editingLedgerIndex: Int? = nil
    @State private var showDeleteConfirmation = false
    @State private var ledgerToDelete: Int?
    @State private var editedLedgerName: String = ""
    @State private var showAddLedgerField: Bool = false

    var body: some View {
        ZStack {
            // Background
            Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)) // #F7F7F7
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Custom Header
                ZStack {
                    Text("Ledger Manager")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)))

                if showAddLedgerField {
                    HStack {
                        TextField("Enter Ledger Name", text: $newLedgerName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                            .foregroundColor(Color(#colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)))

                        Button(action: addLedger) {
                            Text("Save")
                                .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                .font(.body.weight(.bold))
                        }
                        .disabled(newLedgerName.isEmpty)
                    }
                    .padding([.horizontal, .top])
                }

                Divider()
                    .padding(.top, 10)
                ZStack {
                    Color(#colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)) // #F7F7F7

                    List {
                        ForEach(ledgers.indices, id: \.self) { index in
                            HStack {
                                if editingLedgerIndex == index {
                                    TextField("Edit ledger", text: $editedLedgerName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())

                                    Button(action: { saveLedgerChanges(at: index) }) {
                                        Text("Save")
                                            .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                            .bold()
                                    }
                                    .padding(.leading, 8)
                                } else {
                                    Text(ledgers[index])
                                        .font(.subheadline)
                                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                }
                                Spacer()
                                Menu {
                                    Button(action: { startEditingLedger(at: index) }) {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .frame(maxWidth: 70)
                                    .padding(.vertical, 4)

                                    Button(action: { confirmDeleteLedger(at: index) }) {
                                        Label("Delete", systemImage: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .frame(maxWidth: 70)
                                    .padding(.vertical, 4)
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(Color(#colorLiteral(red: 0.5490196078, green: 0.5960784314, blue: 0.6549019608, alpha: 1)))
                                        .font(.subheadline)
                                }
                                .menuStyle(BorderlessButtonMenuStyle())
                            }
                            .listRowBackground(Color.white)
                        }
                        .onMove(perform: moveLedger)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .actionSheet(isPresented: $showDeleteConfirmation) {
                ActionSheet(
                    title: Text("Are you sure you want to delete this ledger?"),
                    message: Text("This action cannot be undone."),
                    buttons: [
                        .destructive(Text("Delete")) {
                            if let index = ledgerToDelete {
                                deleteLedger(at: index)
                            }
                        },
                        .cancel()
                    ]
                )
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    Button(action: { showAddLedgerField.toggle() }) {
                        Image(systemName: "plus.circle")
                            .imageScale(.large)
                            .foregroundColor(Color(#colorLiteral(red: 0.298, green: 0.3059, blue: 0.6078, alpha: 0.7995)))
                    }
                    .padding(.vertical, 60)
                    .padding(.horizontal, 20)
                }
                Divider()
                    .padding(.horizontal)
                    .padding(.top, 40)
            }
        }
    }

    private func addLedger() {
        if !newLedgerName.isEmpty {
            ledgers.append(newLedgerName)
            saveLedgers()
            newLedgerName = ""
            showAddLedgerField = false
        }
    }

    private func startEditingLedger(at index: Int) {
        editingLedgerIndex = index
        editedLedgerName = ledgers[index]
    }

    private func saveLedgerChanges(at index: Int) {
        if !editedLedgerName.isEmpty {
            ledgers[index] = editedLedgerName
            saveLedgers()
        }
        stopEditing()
    }

    private func stopEditing() {
        editingLedgerIndex = nil
        editedLedgerName = ""
    }

    private func confirmDeleteLedger(at index: Int) {
        ledgerToDelete = index
        showDeleteConfirmation = true
    }

    private func deleteLedger(at index: Int) {
        ledgers.remove(at: index)
        saveLedgers()
        ledgerToDelete = nil
    }

    private func moveLedger(from source: IndexSet, to destination: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            ledgers.move(fromOffsets: source, toOffset: destination)
            saveLedgers()
        }
    }

    private func saveLedgers() {
        UserDefaults.standard.set(ledgers, forKey: "ledgers")
    }
}
// Preview
struct LedgerManagerView_Previews: PreviewProvider {
    static var previews: some View {
        LedgerManagerView()
    }
}
