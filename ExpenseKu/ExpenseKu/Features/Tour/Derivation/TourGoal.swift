//
//  TourGoal.swift
//  ExpenseKu
//

import Foundation

nonisolated enum TourGoal: Equatable, Sendable {
    case editorOpened
    case amount(Decimal)
    case category(String)
    case person(String)
    case account(String)
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

    func isMet(by event: TourEvent) -> Bool {
        switch (self, event) {
        case (.editorOpened, .editorOpened), (.saved, .saved), (.receiptTapped, .receiptTapped),
             (.receiptFilled, .receiptFilled), (.searchOpened, .searchOpened), (.leaderboard, .leaderboard):
            true
        case (.amount(let goal), .amount(let amount)):
            goal == amount
        case (.category(let goal), .category(let name)):
            name == goal
        case (.person(let goal), .people(let names)):
            names.contains(goal)
        case (.account(let goal), .account(let name)):
            name == goal
        case (.cycle(let goal), .cycle(let isCurrent)):
            goal == isCurrent
        case (.lens(let goal), .lens(let lens)):
            goal == lens
        case (.search(let goal), .search(let query)):
            query.trimmingCharacters(in: .whitespaces).compare(goal, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        case (.tab(let goal), .tab(let tab)):
            goal == tab
        case (.categoryDetail(let goal), .categoryDetail(let name)):
            goal == name
        default:
            false
        }
    }
}
