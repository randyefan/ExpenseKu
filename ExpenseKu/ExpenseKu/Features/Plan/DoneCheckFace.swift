//
//  DoneCheckFace.swift
//  ExpenseKu
//

import SwiftUI

/// The glyph alone. The washed discs follow the design system's `DoneCheck · Auto`,
/// `· Auto funded` and `· Envelope funded`: the ring is what tells a covered Auto item
/// from one that is not.
struct DoneCheckFace: View {
    let state: DoneCheckState

    var body: some View {
        switch state {
        case .todo:
            glyph("circle", tint: Theme.textSecondary.opacity(0.6))
        case .funded:
            glyph("circle.lefthalf.filled", tint: Theme.accent)
        case .done:
            glyph("checkmark.circle.fill", tint: Theme.accent)
        case .autoPosted:
            glyph("bolt.circle.fill", tint: Theme.accent)
        case .envelope:
            glyph("tray.fill", tint: Theme.textSecondary.opacity(0.7), size: 16)
        case .auto:
            disc("bolt.fill", ringed: false)
        case .autoFunded:
            disc("bolt.fill", ringed: true)
        case .envelopeFunded:
            disc("tray.fill", ringed: false)
        }
    }

    private func glyph(_ name: String, tint: Color, size: CGFloat = 22) -> some View {
        Image(systemName: name)
            .font(.system(size: size))
            .foregroundStyle(tint)
    }

    private func disc(_ name: String, ringed: Bool) -> some View {
        Image(systemName: name)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.accentText)
            .frame(width: 26, height: 26)
            .background(Theme.accent.opacity(Theme.tintFillOpacity), in: .circle)
            .overlay {
                if ringed {
                    Circle().stroke(Theme.accent, lineWidth: 1.5)
                }
            }
    }
}
