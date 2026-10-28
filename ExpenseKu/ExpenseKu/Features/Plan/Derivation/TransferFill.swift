//
//  TransferFill.swift
//  ExpenseKu
//
//  How much of a transfer line is in its Account, read off its items
//  (docs/prd/partial-transfer.md §5.1). An item is in once it is Funded or Done.
//
//  The line's tick used to be a flag the owner set, independent of its items
//  (payday-planning.md decision 25). With income arriving in rounds that flag could not
//  say "BCA is half done", and it could disagree with the items' own ◐. Reading the
//  items leaves one truth for the line, the plan rows and the bank headers.
//

import Foundation

nonisolated enum TransferFill: Equatable {
    case nothingIn
    case partIn
    case allIn

    static func of(_ members: [TransferMember]) -> TransferFill {
        of(inCount: members.count(where: \.isIn), of: members.count)
    }

    static func of(inCount: Int, of count: Int) -> TransferFill {
        if inCount == 0 { return .nothingIn }
        return inCount == count ? .allIn : .partIn
    }

    var systemImage: String {
        switch self {
        case .nothingIn: "circle"
        case .partIn: "circle.lefthalf.filled"
        case .allIn: "checkmark.circle.fill"
        }
    }
}
