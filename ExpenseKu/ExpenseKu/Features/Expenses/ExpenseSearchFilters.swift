//
//  ExpenseSearchFilters.swift
//  ExpenseKu
//
//  The two chips that narrow a search: one category, one period. Deliberately the
//  same `FilterChip` menus the People leaderboard uses, so filtering means the
//  same thing wherever the owner meets it.
//
//  The category is bound by *name* rather than by `Category`, so no live model is
//  held in view state (see ExpenseSearch.swift).
//

import SwiftUI

struct ExpenseSearchFilters: View {
    let categoryNames: [String]
    @Binding var categoryName: String?
    @Binding var range: DateRangeFilter

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                Menu {
                    Button("All") { categoryName = nil }
                    Divider()
                    ForEach(categoryNames, id: \.self) { name in
                        Button(name) { categoryName = name }
                    }
                } label: {
                    FilterChip(label: "Category", value: categoryName ?? "All")
                }

                Menu {
                    Picker("Period", selection: $range) {
                        ForEach(DateRangeFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                } label: {
                    FilterChip(label: "Period", value: range.label)
                }
            }
            .padding(.horizontal, Metric.screenPadding)
        }
        .scrollIndicators(.hidden)
        .padding(.bottom, Metric.cardGap)
    }
}

#Preview {
    @Previewable @State var categoryName: String? = nil
    @Previewable @State var range: DateRangeFilter = .allTime

    VStack {
        ExpenseSearchFilters(
            categoryNames: ["Kopi", "Makan", "Transport"],
            categoryName: $categoryName,
            range: $range
        )
        Spacer()
    }
    .warmBackground()
}
