//
//  EmptyNotice.swift
//  ExpenseKu
//
//  Which message stands in for a list a filter has emptied (docs/prd/expense-filter.md
//  §4.6). This filter's message wins only when it is what emptied the list; when its
//  matches exist and the plan filter's half is what is empty, the plan filter's message
//  shows, as plan-filter.md §4.4 wrote it.
//

import Foundation

nonisolated struct EmptyNotice: Equatable {
    let title: String
    let detail: String
    var offersClearFilters = false

    static let filterTitle = "Nothing matches these filters"
    static let filterPeriodMessage = "Nothing matches these filters in this period."

    static func cycle(
        filter: ExpenseFilter,
        filteredIsEmpty: Bool,
        planFilter: PlanFilter?,
        span: String
    ) -> EmptyNotice? {
        if !filter.isEmpty, filteredIsEmpty {
            return EmptyNotice(
                title: filterTitle,
                detail: "No expenses in \(span) match these filters.",
                offersClearFilters: true
            )
        }
        return planFilter.map {
            EmptyNotice(title: $0.emptyCycleTitle, detail: $0.emptyCycleDetail(span: span))
        }
    }

    static func day(
        filter: ExpenseFilter,
        filteredDayIsEmpty: Bool,
        planFilter: PlanFilter?,
        dayPhrase: String
    ) -> EmptyNotice? {
        if !filter.isEmpty, filteredDayIsEmpty {
            return EmptyNotice(
                title: "Nothing matches \(dayPhrase)",
                detail: "Clear the filters to show every expense.",
                offersClearFilters: true
            )
        }
        return planFilter.map {
            EmptyNotice(title: $0.emptyDayTitle(dayPhrase: dayPhrase), detail: $0.emptyDayDetail)
        }
    }

    static func chart(filter: ExpenseFilter, filteredIsEmpty: Bool, planFilter: PlanFilter?) -> String? {
        if !filter.isEmpty, filteredIsEmpty { return filterPeriodMessage }
        return planFilter?.emptyPeriodMessage
    }
}
