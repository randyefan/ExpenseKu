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
    @Query(sort: \Person.name) private var people: [Person]
    @State private var showingNew = false

    var body: some View {
        List {
            ForEach(people) { person in
                Button {
                    toggle(person)
                } label: {
                    HStack {
                        Text(person.name)
                        Spacer()
                        if isSelected(person) {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
            Button {
                showingNew = true
            } label: {
                Label("New Person", systemImage: "plus")
            }
        }
        .navigationTitle("People")
        .sheet(isPresented: $showingNew) {
            NavigationStack {
                NameEditorView<Person>(title: "New Person", makeNew: { Person() }) { created in
                    if !isSelected(created) { selection.append(created) }
                }
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
