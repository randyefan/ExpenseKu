//
//  LeaderboardFilters.swift
//  ExpenseKu
//
//  The period / category / account menus above the People leaderboard.
//

import SwiftUI
import SwiftData

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
                    Picker(AppLocalization.string(.period), selection: $range) {
                        ForEach(DateRangeFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                } label: {
                    FilterChip(label: AppLocalization.string(.period), value: range.label)
                }

                Menu {
                    Button(AppLocalization.string(.allItems)) { category = nil }
                    Divider()
                    ForEach(categories) { item in
                        Button(item.name) { category = item }
                    }
                } label: {
                    FilterChip(label: AppLocalization.string(.category), value: category?.name ?? AppLocalization.string(.allItems))
                }

                Menu {
                    Button(AppLocalization.string(.allItems)) { account = nil }
                    Divider()
                    ForEach(accounts) { item in
                        Button(item.name) { account = item }
                    }
                } label: {
                    FilterChip(label: AppLocalization.string(.account), value: account?.name ?? AppLocalization.string(.allItems))
                }
            }
        }
        .sensoryFeedback(.selection, trigger: range)
    }
}
