//
//  DebugHarness.swift
//  ExpenseKu
//
//  DEBUG-only presenter that lets screenshot launch args reach the modal and
//  pushed screens the plain deep-links can't — the expense editor, its three
//  pickers, and the inline name-duplicate prompt. Never compiled into release.
//
//  Reached via `-startScreen editor|picker-category|picker-people|
//  picker-account|name-duplicate|category-editor|account-editor` (see
//  DebugLaunch + RootView).
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
    @State private var payday: Int = Payday.current

    var body: some View {
        content
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
            NavigationStack { ExpenseEditorView() }
        case "picker-category":
            NavigationStack { CategoryPicker(selection: $category) }
        case "picker-people":
            NavigationStack { PeoplePicker(selection: $selectedPeople) }
        case "picker-account":
            NavigationStack { AccountPicker(selection: $account) }
        case "category-editor":
            // Edit a seeded category so the appearance picker shows a live preview.
            NavigationStack {
                AppearanceEntityEditor<Category>(
                    title: categories.first == nil ? "New Category" : "Edit Category",
                    editing: categories.first,
                    makeNew: { Category() }
                )
            }
        case "account-editor":
            NavigationStack {
                AppearanceEntityEditor<Account>(
                    title: accounts.first == nil ? "New Account" : "Edit Account",
                    editing: accounts.first,
                    makeNew: { Account() }
                )
            }
        case "settings":
            // Brings its own NavigationStack.
            TransactionSettingsView(payday: $payday)
        case "name-duplicate":
            // Prefill with a seeded category name so the dedup prompt shows.
            NavigationStack {
                NameEditorView<Category, EmptyView>(
                    title: "New Category",
                    makeNew: { Category() },
                    debugPrefill: categories.first?.name ?? "Makan"
                )
            }
        default:
            EmptyView()
        }
    }
}
#endif
