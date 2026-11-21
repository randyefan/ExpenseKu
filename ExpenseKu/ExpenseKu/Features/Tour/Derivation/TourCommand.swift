//
//  TourCommand.swift
//  ExpenseKu
//
//  What the tour asks a real screen to do when a beat begins: the screens own their state,
//  so the tour can only request a change and let them carry it out.
//

import Foundation

nonisolated enum TourCommand: Equatable, Sendable {
    case openEditor
    case scrollEditor(TourTarget)
    case clearSearch
    case revealPlanRows
    case showToday
    case popInsights
}

nonisolated struct TourCommandRequest: Equatable, Sendable {
    let id: Int
    let command: TourCommand
}
