//
//  TourOverlay.swift
//  ExpenseKu
//
//  Draws the mission on whichever layer is on top. A sheet the real screen presents (the
//  expense editor) covers anything drawn beneath it, so the editor carries its own overlay
//  and the tour switches to it while the editor is open.
//

import SwiftUI

struct TourOverlay: View {
    let layer: TourLayer
    @Environment(\.tour) private var tour

    var body: some View {
        if let tour, tour.activeLayer == layer, tour.scene == .playing {
            TourMissionOverlay(session: tour)
        }
    }
}

extension View {
    func tourLayer(_ layer: TourLayer) -> some View {
        overlay { TourOverlay(layer: layer) }
    }
}
