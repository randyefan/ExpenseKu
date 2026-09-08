//
//  HueDial.swift
//  ExpenseKu — DesignSystem
//
//  A draggable spectrum. The thumb follows the finger across the full hue circle
//  and snaps to the twelve palette hues, ticking as it passes each one, so a
//  colour can be dialled in as precisely or as casually as the owner wants.
//

import SwiftUI

struct HueDial: View {
    @Binding var hue: Double
    var snapPoints: [Double] = []
    var isAuto: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var dragging = false

    private let track: CGFloat = 46
    private let thumb: CGFloat = 38
    private let snapWindow: Double = 0.018

    private var tint: Color { Theme.tint(hue: hue) }

    var body: some View {
        GeometryReader { geo in
            let span = max(1, geo.size.width - thumb)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(spectrum)
                    .frame(height: track)
                    .overlay(ticks(width: geo.size.width))
                    .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))

                thumbView
                    .offset(x: hue * span)
            }
            .frame(height: track)
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($dragging) { _, state, _ in state = true }
                    .onChanged { value in
                        let raw = min(max(0, (value.location.x - thumb / 2) / span), 1)
                        hue = snapped(raw)
                    }
            )
        }
        .frame(height: track)
        .sensoryFeedback(.selection, trigger: nearestSnapIndex)
        .accessibilityElement()
        .accessibilityLabel("Colour")
        .accessibilityValue("\(Int(hue * 360)) degrees")
        .accessibilityAdjustableAction { direction in
            let step = 1.0 / 24
            switch direction {
            case .increment: hue = min(1, hue + step)
            case .decrement: hue = max(0, hue - step)
            @unknown default: break
            }
        }
    }

    private var spectrum: LinearGradient {
        LinearGradient(
            colors: stride(from: 0.0, through: 1.0, by: 1.0 / 24).map { Theme.tint(hue: $0) },
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func ticks(width: CGFloat) -> some View {
        let span = max(1, width - thumb)
        return ZStack(alignment: .leading) {
            ForEach(snapPoints, id: \.self) { point in
                Capsule()
                    .fill(Theme.onTint.opacity(0.5))
                    .frame(width: 2, height: 10)
                    .offset(x: thumb / 2 - 1 + point * span)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var thumbView: some View {
        ZStack {
            Circle()
                .fill(Theme.card)
                .frame(width: thumb, height: thumb)
                .shadow(color: .black.opacity(0.18), radius: 5, y: 2)

            Circle()
                .fill(tint)
                .frame(width: thumb - 10, height: thumb - 10)

            if isAuto {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.onTint)
            }
        }
        .scaleEffect(dragging ? 1.18 : 1)
        .motion(Motion.snap, value: dragging)
        .motion(reduceMotion ? Motion.reduced : Motion.snap, value: hue)
    }

    private func snapped(_ raw: Double) -> Double {
        guard let near = snapPoints.min(by: { abs($0 - raw) < abs($1 - raw) }),
              abs(near - raw) < snapWindow else { return raw }
        return near
    }

    private var nearestSnapIndex: Int { Int((hue * 48).rounded()) }
}

#Preview {
    @Previewable @State var hue = 0.12
    VStack(spacing: 24) {
        HueDial(hue: $hue, snapPoints: [0, 0.25, 0.5, 0.75])
        Circle().fill(Theme.tint(hue: hue)).frame(width: 60, height: 60)
    }
    .padding()
    .appBackground()
}
