//
//  TourBeat.swift
//  ExpenseKu
//
//  One bubble of a mission (welcome-tour.md §4.3, §4.5). An act waits for the user to do
//  something to the target; a watch waits for the tour itself; a spotlight waits for Next;
//  a moment lights a result and moves on by itself.
//

import Foundation

nonisolated struct TourBeat: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case act(TourGoal)
        case watch(TourGoal)
        case spotlight
        case moment
    }

    let kind: Kind
    let line: TourLine
    var target: TourTarget?
    var readout: TourTarget?
    var companion: TourTarget?
    var nudge: TourLine?
    var command: TourCommand?

    var goal: TourGoal? {
        switch kind {
        case .act(let goal), .watch(let goal): goal
        case .spotlight, .moment: nil
        }
    }

    var pose: WalletPose {
        switch kind {
        case .act: .pointing
        case .watch, .spotlight: .talking
        case .moment: .happy
        }
    }

    var letsTargetThrough: Bool {
        if case .act = kind { true } else { false }
    }
}

nonisolated enum WalletPose: String, CaseIterable, Sendable {
    case waving, talking, pointing, happy, confused

    var imageName: String {
        switch self {
        case .waving: "WalletWaving"
        case .talking: "WalletTalking"
        case .pointing: "WalletPointing"
        case .happy: "WalletHappy"
        case .confused: "WalletConfused"
        }
    }

    var accessibilityLabel: LocalizedStringResource {
        switch self {
        case .waving: .tourWalletWaving
        case .talking: .tourWalletTalking
        case .pointing: .tourWalletPointing
        case .happy: .tourWalletHappy
        case .confused: .tourWalletConfused
        }
    }
}
