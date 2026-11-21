//
//  TourEvent.swift
//  ExpenseKu
//
//  What the real screens report while they run inside the tour (welcome-tour.md §4.3): a
//  mission completes when one of these meets its goal, never on a Next button.
//

import Foundation

nonisolated enum TourLens: Hashable, Sendable {
    case list, month, plan
}

nonisolated enum TourTab: Hashable, Sendable {
    case expenses, insights, manage
}

nonisolated enum TourEvent: Equatable, Sendable {
    case editorOpened
    case editorClosed
    case amount(Decimal)
    case category(String?)
    case people([String])
    case account(String?)
    case saved
    case receiptTapped
    case receiptFilled
    case cycle(isCurrent: Bool)
    case lens(TourLens)
    case searchOpened
    case search(String)
    case tab(TourTab)
    case categoryDetail(String)
    case leaderboard
}
