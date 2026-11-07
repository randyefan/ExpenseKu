//
//  WhenTap.swift
//  ExpenseKu
//

import Foundation

/// The chip the owner tapped and the date it set, so the chip stays lit after the
/// clock moves past the minute it was tapped in.
nonisolated struct WhenTap: Equatable, Sendable {
    let shortcut: WhenShortcut
    let date: Date
}
