//
//  CategoryGrid.swift
//  ExpenseKu
//
//  CATEGORY in the expense editor (docs/prd/quick-entry-form.md §4.2): the seven most used
//  Categories as tiles in fixed positions, then All… for the rest.
//

import SwiftUI
import SwiftData

struct CategoryGrid: View {
    let categories: [Category]
    @Binding var selection: Category?
    let onShowAll: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        QuickEntrySection(title: AppLocalization.string(.category), isRequired: selection == nil) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(categories) { category in
                    let isSelected = category.persistentModelID == selection?.persistentModelID
                    Button {
                        selection = category
                    } label: {
                        CategoryTile(name: category.name, isSelected: isSelected) {
                            CategoryIcon(category: category, size: 30)
                        }
                    }
                    .buttonStyle(.pressableCard)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
                Button(action: onShowAll) {
                    CategoryTile(name: AppLocalization.string(.all), isSelected: false, isMuted: true) {
                        CategoryIcon(symbol: "square.grid.2x2", tint: Theme.textSecondary, size: 30)
                    }
                }
                .buttonStyle(.pressableCard)
                .accessibilityLabel(AppLocalization.string(.allCategories))
            }
            .padding(.horizontal, Metric.screenPadding)
        }
    }
}
