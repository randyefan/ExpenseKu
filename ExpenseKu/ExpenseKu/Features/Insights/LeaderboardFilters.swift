//
//  LeaderboardFilters.swift
//  ExpenseKu
//
//  The period / category / account menus above the People leaderboard.
//

import SwiftUI

struct LeaderboardFilters: View {
    @Binding var range: DateRangeFilter
    @Binding var category: Category?
    @Binding var account: Account?
    let categories: [Category]
    let accounts: [Account]

    var body: some View {
        ChipRail {
            Group {
                Menu {
                    Picker("Period", selection: $range) {
                        ForEach(DateRangeFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                } label: {
                    FilterChip(label: "Period", value: range.label)
                }

                Menu {
                    Button("All") { category = nil }
                    Divider()
                    ForEach(categories) { item in
                        Button(item.name) { category = item }
                    }
                } label: {
                    FilterChip(label: "Category", value: category?.name ?? "All")
                }

                Menu {
                    Button("All") { account = nil }
                    Divider()
                    ForEach(accounts) { item in
                        Button(item.name) { account = item }
                    }
                } label: {
                    FilterChip(label: "Account", value: account?.name ?? "All")
                }
            }
        }
        .sensoryFeedback(.selection, trigger: range)
    }
}
