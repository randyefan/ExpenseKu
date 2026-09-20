//
//  CycleHeadline.swift
//  ExpenseKu
//
//  The labelled pair in the shared cycle header. The header keeps its shape across
//  all three lenses and swaps what it names (PRD §6.2): `SPENDING / Rp 220.000`
//  becomes `SISA / Rp 2.000.000` while the Plan lens is active.
//
//  The label always names the number, so no figure ever changes meaning silently —
//  which is the whole reason the two lenses can share one header. Pure, so the swap
//  and the negative-Sisa tint are unit tests rather than a screenshot.
//

import Foundation

nonisolated struct CycleHeadline: Equatable {
    let label: String
    let amount: Decimal
    let tint: Tint

    /// Which colour the figure takes. Resolved to a `Color` at the view, so this type
    /// stays free of SwiftUI and testable.
    enum Tint: Equatable {
        /// The ordinary case. A figure this large in accent reads as an alarm, and
        /// the accent is reserved for actions and selected states.
        case neutral
        /// A plan that allocates past its income (frame I6).
        case negative
    }

    /// What the List and Month lenses show: money that has already left.
    static func spending(_ total: Decimal) -> CycleHeadline {
        CycleHeadline(label: "Spending", amount: total, tint: .neutral)
    }

    /// What the Plan lens shows. Sisa is a plan figure, not a balance — it does not
    /// move as money is spent (§9.9).
    static func sisa(_ sisa: Decimal) -> CycleHeadline {
        CycleHeadline(label: "Sisa", amount: sisa, tint: sisa < 0 ? .negative : .neutral)
    }
}
