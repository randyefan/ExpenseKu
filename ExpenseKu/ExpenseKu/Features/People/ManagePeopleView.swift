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
                Button { editor = EditorTarget(person: person) } label: {
                    HStack(spacing: 12) {
                        PersonAvatar(name: person.name, size: 36)
                        Text(person.name)
                            .font(.dsBody)
                            .foregroundStyle(Theme.text)
                        Spacer()
                    }
                }
                .listRowBackground(Theme.card)
            }
            .onDelete(perform: delete)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg)
        .navigationTitle("People")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { editor = EditorTarget(person: nil) } label: {
                    Label("Add Person", systemImage: "plus")
                }
                .accentCircleButton()
            }
        }
        .overlay {
            if people.isEmpty {
                EmptyStateView(title: "No People", systemImage: "person.2",
                    message: "Add one with the + button.")
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
