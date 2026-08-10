//
//  PeoplePicker.swift
//  ExpenseKu
//
//  Multi-select people picker for the expense editor (ticket 05). Tag zero or
//  more companions; create one inline through the de-dup editor.
//

import SwiftUI
import SwiftData

struct PeoplePicker: View {
    @Binding var selection: [Person]
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.name) private var allPeople: [Person]
    /// "Me" pinned to the top, then everyone else alphabetically.
    private var people: [Person] {
        allPeople.filter(\.isMe) + allPeople.filter { !$0.isMe }
    }
    @State private var showingNew = false

    var body: some View {
        List {
            Section {
                ForEach(people) { person in
                    Button {
                        toggle(person)
                    } label: {
                        HStack(spacing: 12) {
                            PersonAvatar(name: person.name, size: 36)
                            Text(person.name)
                                .font(.dsBody)
                                .foregroundStyle(Theme.text)
                            Spacer()
                            Image(systemName: isSelected(person) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isSelected(person) ? Theme.accent : Theme.textSecondary.opacity(0.5))
                        }
                    }
                    .listRowBackground(Theme.card)
                }
            }
            Section {
                Button { showingNew = true } label: {
                    PickerAddRow(title: "New Person")
                }
                .listRowBackground(Theme.card)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("People")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .sheet(isPresented: $showingNew) {
            NavigationStack {
                NameEditorView<Person>(title: "New Person", makeNew: { Person() }, onCommit: { created in
                    if !isSelected(created) { selection.append(created) }
                })
            }
        }
    }

    private func isSelected(_ person: Person) -> Bool {
        selection.contains { $0.persistentModelID == person.persistentModelID }
    }

    private func toggle(_ person: Person) {
        if let index = selection.firstIndex(where: { $0.persistentModelID == person.persistentModelID }) {
            selection.remove(at: index)
        } else {
            selection.append(person)
        }
    }
}
