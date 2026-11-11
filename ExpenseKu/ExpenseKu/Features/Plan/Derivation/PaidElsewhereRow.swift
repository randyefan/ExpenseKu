//
//  PaidElsewhereRow.swift
//  ExpenseKu
//
//  One Account in an envelope's PAID ELSEWHERE section (docs/prd/paid-elsewhere.md §4.3).
//  Its check and caption are read off its expenses' marks every time, so a Grab logged
//  after a round makes the row owe again without a tick to undo (§4.6).
//

import Foundation
import SwiftData

nonisolated struct PaidElsewhereRow: Identifiable, Equatable {
    let id: PersistentIdentifier
    let accountName: String
    let plate: AccountPlateStyle
    /// The envelope's own Account, the one money is moved from: "Jago".
    let homeName: String
    let members: [PaidElsewhereMember]

    init(account: Account, homeName: String, members: [PaidElsewhereMember]) {
        id = account.persistentModelID
        accountName = account.name
        plate = AccountPlateStyle(account: account)
        self.homeName = homeName
        self.members = members.sorted(by: PaidElsewhereMember.precedes)
    }

    var total: Decimal { members.reduce(0) { $0 + $1.amount } }
    var moved: Decimal { members.filter(\.isMoved).reduce(0) { $0 + $1.amount } }
    var toMove: Decimal { total - moved }

    var fill: TransferFill { .of(inCount: members.count(where: \.isMoved), of: members.count) }

    var caption: String {
        switch fill {
        case .nothingIn: AppLocalization.string(.moveFrom(homeName))
        case .partIn: AppLocalization.string(.toMoveMoved(toMove.formattedIDR(), moved.formattedIDR()))
        case .allIn: AppLocalization.string(.movedFrom(homeName))
        }
    }

    var fillDescription: String {
        switch fill {
        case .nothingIn: AppLocalization.string(.nothingMovedYet)
        case .partIn: AppLocalization.string(.partMoved)
        case .allIn: AppLocalization.string(.allMoved)
        }
    }

    /// Rows with something to move lead, by what is left to move ↓; rows with all of it
    /// moved follow, by total ↓, and stay so a move can be undone (§4.4).
    static func precedes(_ a: PaidElsewhereRow, _ b: PaidElsewhereRow) -> Bool {
        let aOwes = a.toMove > 0, bOwes = b.toMove > 0
        if aOwes != bOwes { return aOwes }
        let aKey = aOwes ? a.toMove : a.total
        let bKey = bOwes ? b.toMove : b.total
        if aKey != bKey { return aKey > bKey }
        return a.accountName.localizedStandardCompare(b.accountName) == .orderedAscending
    }
}
