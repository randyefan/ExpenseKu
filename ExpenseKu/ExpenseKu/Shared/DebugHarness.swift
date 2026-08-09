//
//  DebugHarness.swift
//  ExpenseKu
//
//  DEBUG-only presenter that lets screenshot launch args reach the modal and
//  pushed screens the plain deep-links can't — the expense editor, its three
//  pickers, and the inline name-duplicate prompt. Never compiled into release.
//
//  Reached via `-startScreen editor|picker-category|picker-people|
//  picker-account|name-duplicate` (see DebugLaunch + RootView).
//

#if DEBUG
import SwiftUI
import SwiftData

struct DebugHarness: View {
    let screen: String

    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Person.name) private var people: [Person]
    @Query(sort: \Account.name) private var accounts: [Account]

    @State private var category: Category?
    @State private var account: Account?
    @State private var selectedPeople: [Person] = []

    var body: some View {
        NavigationStack {
            content
        }
        .onAppear {
            // Preselect so the coral checkmark / selected state is visible.
            if category == nil { category = categories.first }
            if selectedPeople.isEmpty { selectedPeople = Array(people.prefix(2)) }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch screen {
        case "editor":
            ExpenseEditorView()
        case "picker-category":
            CategoryPicker(selection: $category)
        case "picker-people":
            PeoplePicker(selection: $selectedPeople)
        case "picker-account":
            AccountPicker(selection: $account)
        case "name-duplicate":
            // Prefill with a seeded category name so the dedup prompt shows.
            NameEditorView<Category>(
                title: "New Category",
                makeNew: { Category() },
                debugPrefill: categories.first?.name ?? "Makan"
            )
        default:
            EmptyView()
        }
    }
}
#endif
