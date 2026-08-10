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
    @Query(sort: \Person.name) private var allPeople: [Person]
    @State private var editor: EditorTarget?

    /// "Me" pinned to the top, then everyone else alphabetically.
    private var people: [Person] {
        allPeople.filter(\.isMe) + allPeople.filter { !$0.isMe }
    }

    var body: some View {
        List {
            ForEach(people) { person in
                row(for: person)
                    .listRowBackground(Theme.card)
                    .deleteDisabled(person.isMe)
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

    /// A normal person is tappable to rename; the protected "Me" is a plain,
    /// non-editable row marked "You".
    @ViewBuilder private func row(for person: Person) -> some View {
        if person.isMe {
            HStack(spacing: 12) {
                PersonAvatar(name: person.name, size: 36)
                Text(person.name)
                    .font(.dsBody)
                    .foregroundStyle(Theme.text)
                Spacer()
                Text("You")
                    .font(.dsSubhead)
                    .foregroundStyle(Theme.textSecondary)
            }
        } else {
            Button { editor = EditorTarget(person: person) } label: {
                HStack(spacing: 12) {
                    PersonAvatar(name: person.name, size: 36)
                    Text(person.name)
                        .font(.dsBody)
                        .foregroundStyle(Theme.text)
                    Spacer()
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets where !people[index].isMe {
            context.delete(people[index])
        }
    }

    struct EditorTarget: Identifiable {
        let id = UUID()
        let person: Person?
    }
}
