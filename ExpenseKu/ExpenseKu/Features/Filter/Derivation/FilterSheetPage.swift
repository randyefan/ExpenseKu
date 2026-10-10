//
//  FilterSheetPage.swift
//  ExpenseKu
//
//  A page pushed inside the Filter sheet: the plan filter's choice, or one dimension's
//  checklist (docs/prd/expense-filter.md §4.3, §4.8).
//

import Foundation

nonisolated enum FilterSheetPage: Hashable {
    case plan
    case dimension(FilterDimension)
}
