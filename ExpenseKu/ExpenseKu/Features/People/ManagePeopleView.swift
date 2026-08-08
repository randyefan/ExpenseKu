//
//  ManagePeopleView.swift
//  ExpenseKu
//
//  CRUD for people (companions). Add/rename route through the de-dup editor
//  (ADR-0002); delete removes the person from expenses via .nullify (ADR-0001).
//

import SwiftUI
import SwiftData

struct ManagePeopleView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Person.name) private var people: [Person]
    @State private var editor: EditorTarget?

    var body: some View {
        List {
            ForEach(people) { person in
                Button(person.name) { editor = EditorTarget(person: person) }
                    .foregroundStyle(.primary)
            }
            .onDelete(perform: delete)
        }
        .navigationTitle("People")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { editor = EditorTarget(person: nil) } label: {
                    Label("Add Person", systemImage: "plus")
                }
            }
        }
        .overlay {
            if people.isEmpty {
                ContentUnavailableView("No People", systemImage: "person.2",
                    description: Text("Add one with the + button."))
            }
        }
        .sheet(item: $editor) { target in
            NavigationStack {
                NameEditorView<Person>(
                    title: target.person == nil ? "New Person" : "Edit Person",
                    editing: target.person,
                    makeNew: { Person() }
                )
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { context.delete(people[index]) }
    }

    struct EditorTarget: Identifiable {
        let id = UUID()
        let person: Person?
    }
}
