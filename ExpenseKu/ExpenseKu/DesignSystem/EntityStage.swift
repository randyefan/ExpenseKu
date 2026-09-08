//
//  EntityStage.swift
//  ExpenseKu — DesignSystem
//
//  The subject of every add/edit screen, on a card with two faces: the mark at
//  the size it deserves, and — after a tap flips it — the same entity drawn as a
//  ledger row. Dragging tilts it in parallax. All of it goes still under Reduce
//  Motion.
//

import SwiftUI

struct EntityStage: View {
    enum Mark: Hashable {
        case symbol(String)
        case initial(String)
    }

    let mark: Mark
    let tint: Color
    let name: String
    var placeholder: String
    var caption: String
    var sampleAmount: Decimal = 45_000
    var onShuffle: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsContext = false
    @State private var tilt: CGSize = .zero
    @State private var pulse = false
    @State private var primed = false

    private var displayName: String { name.isEmpty ? placeholder : name }
    private var markSize: CGFloat { 92 }

    var body: some View {
        Flip(
            progress: showsContext ? 1 : 0,
            flat: reduceMotion,
            front: markFace,
            back: contextFace
        )
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(Theme.card)
                .stroke(tint.opacity(0.28), lineWidth: 1)
        }
        .rotation3DEffect(.degrees(tilt.width / 16), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
        .rotation3DEffect(.degrees(-tilt.height / 22), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
        .overlay(alignment: .topTrailing) { shuffleButton }
        .contentShape(.rect(cornerRadius: 22))
        .gesture(tiltGesture)
        .onTapGesture { withAnimation(reduceMotion ? Motion.reduced : Motion.sheet) { showsContext.toggle() } }
        .motion(Motion.settle, value: tint)
        .sensoryFeedback(.impact(weight: .light), trigger: showsContext)
        .task(id: PulseKey(mark: mark, tint: tint)) {
            guard primed else {
                primed = true
                return
            }
            guard !reduceMotion else { return }
            pulse = true
            try? await Task.sleep(for: .seconds(0.16))
            guard !Task.isCancelled else { return }
            pulse = false
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(displayName)
        .accessibilityHint(showsContext ? "Showing how it looks in a list. Double tap to flip back."
                                        : "Double tap to see how it looks in a list.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Faces

    private var markFace: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(tint.opacity(Theme.tintFillOpacity))
                Circle().stroke(tint.opacity(0.35), lineWidth: 1)
                markView(size: markSize)
            }
            .frame(width: markSize, height: markSize)
            .scaleEffect(pulse ? 1.06 : 1)
            .motion(Motion.snap, value: pulse)

            VStack(spacing: 3) {
                Text(displayName)
                    .font(.dsTitle).fontWeight(.semibold)
                    .foregroundStyle(name.isEmpty ? Theme.textSecondary : Theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(caption)
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                    .contentTransition(.opacity)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
    }

    private var contextFace: some View {
        VStack(spacing: 12) {
            Text("In your ledger")
                .font(.dsCaption).fontWeight(.semibold)
                .foregroundStyle(Theme.textSecondary)
                .tracking(0.5)

            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(tint.opacity(Theme.tintFillOpacity))
                    markView(size: Metric.iconSize)
                }
                .frame(width: Metric.iconSize, height: Metric.iconSize)

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.dsBody).fontWeight(.semibold)
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                    Text("Today")
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer(minLength: 8)

                MoneyText(sampleAmount, font: .dsBody)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: Metric.rowRadius)
                    .fill(Theme.surface)
            }

            Text("Tap to flip back")
                .font(.dsCaption)
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func markView(size: CGFloat) -> some View {
        switch mark {
        case .symbol(let symbol):
            Image(systemName: symbol)
                .font(.system(size: size * 0.40, weight: .semibold))
                .foregroundStyle(tint)
                .contentTransition(.symbolEffect(.replace))
        case .initial(let letter):
            Text(letter)
                .font(.jakarta(size * 0.38)).fontWeight(.semibold)
                .foregroundStyle(tint)
                .contentTransition(.opacity)
        }
    }

    // MARK: - Interaction

    @ViewBuilder
    private var shuffleButton: some View {
        if let onShuffle, !showsContext {
            Button {
                onShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.accentText)
                    .frame(width: 36, height: 36)
                    .background(Theme.surface, in: Circle())
                    .symbolEffect(.bounce, value: tint)
            }
            .buttonStyle(.pressableCard)
            .padding(10)
            .accessibilityLabel("Shuffle appearance")
        }
    }

    private var tiltGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard !reduceMotion else { return }
                tilt = CGSize(width: max(-70, min(70, value.translation.width)),
                              height: max(-70, min(70, value.translation.height)))
            }
            .onEnded { _ in
                withAnimation(Motion.snap) { tilt = .zero }
            }
    }

    private struct PulseKey: Hashable {
        let mark: Mark
        let tint: Color
    }
}

private struct Flip<Front: View, Back: View>: View, Animatable {
    var progress: Double
    let flat: Bool
    let front: Front
    let back: Back

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        ZStack {
            front.opacity(flat ? 1 - progress : (progress < 0.5 ? 1 : 0))
            back
                .rotation3DEffect(.degrees(flat ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                .opacity(flat ? progress : (progress < 0.5 ? 0 : 1))
        }
        .rotation3DEffect(.degrees(flat ? 0 : progress * 180),
                          axis: (x: 0, y: 1, z: 0), perspective: 0.45)
    }
}

#Preview {
    VStack(spacing: 20) {
        EntityStage(mark: .symbol("cup.and.saucer.fill"), tint: Theme.categoryTint("Kopi"),
                    name: "Kopi", placeholder: "New Category",
                    caption: "Category · Custom icon", onShuffle: {})
        EntityStage(mark: .initial("T"), tint: Theme.categoryTint("Tarisa"),
                    name: "", placeholder: "New Person",
                    caption: "Person · Automatic colour")
    }
    .padding()
    .appBackground()
}
