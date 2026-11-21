//
//  TourMissionOverlay.swift
//  ExpenseKu
//
//  A mission over the real screen (welcome-tour.md §4.3, §4.4): a 72 % scrim with the target
//  cut out and ringed, readouts lit without a ring, and the guide unit beside the target.
//  Only the target's cut-out lets touches through; anything else confuses the wallet.
//
//  The scrim stops short of the keyboard, which iOS draws above every window: the search
//  field mission types through it.
//

import SwiftUI

struct TourMissionOverlay: View {
    let session: TourSession

    @State private var unitHeight: CGFloat = 150

    var body: some View {
        GeometryReader { outer in
            let insets = outer.safeAreaInsets
            GeometryReader { proxy in
                content(size: proxy.size, origin: proxy.frame(in: .global).origin, insets: insets)
            }
            .ignoresSafeArea(.container)
        }
        .sensoryFeedback(.success, trigger: session.completions)
        .sensoryFeedback(.warning, trigger: session.touch?.id)
        .sensoryFeedback(.impact(weight: .light), trigger: session.hops)
        .onChange(of: session.line) { _, line in
            guard let line else { return }
            AccessibilityNotification.Announcement(AppLocalization.string(line.resource)).post()
        }
    }

    @ViewBuilder
    private func content(size: CGSize, origin: CGPoint, insets: EdgeInsets) -> some View {
        let beat = session.beat
        let frames = TourFrames(registry: session.targets, origin: origin, size: size, safeTop: insets.top)
        let target = beat?.target.flatMap(frames.frame(for:))
        let readout = beat?.readout.flatMap(frames.frame(for:))
        let companion = beat?.companion.flatMap(frames.frame(for:))
        let width = min(size.width - 32, 380)
        let bounds = CGRect(x: 16, y: insets.top + 6, width: size.width - 32,
                            height: max(size.height - insets.top - insets.bottom - 12, unitHeight))
        let placement = TourPlacement.place(target: target?.rect, pointer: companion?.rect,
                                            unit: CGSize(width: width, height: unitHeight),
                                            in: bounds)
        let isWatching = if case .watch = beat?.kind { true } else { false }
        let lets = beat?.letsTargetThrough == true

        ZStack(alignment: .topLeading) {
            if isWatching {
                Color.clear
                    .contentShape(.rect)
            } else {
                let lit = [target, readout, companion].compactMap { $0 }.map(TourHole.init)
                let passable = lets ? [target].compactMap { $0 }.map(TourHole.init) : []
                TourScrimShape(holes: lit)
                    .fill(Theme.tourScrim, style: FillStyle(eoFill: true))
                    .contentShape(TourScrimShape(holes: passable), eoFill: true)
                    .onTapGesture { location in session.wrongTouch(at: location) }
                    .accessibilityHidden(true)
                    .animation(Motion.settle, value: lit)

                if let target {
                    TourTargetRing(hole: TourHole(target), pulses: lets, nudges: session.touch?.id ?? 0)
                }
                if let companion {
                    TourTargetRing(hole: TourHole(companion), pulses: false, nudges: 0, dashed: true)
                }
            }

            if let line = session.line {
                TourGuideUnit(session: session, line: AppLocalization.string(line.resource),
                              placement: placement, width: width)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { unitHeight = $0 }
                    .offset(x: placement.origin.x, y: placement.origin.y)
                    .animation(.spring(duration: 0.5, bounce: 0.25), value: placement)
            }

            TourCoinBurst(trigger: session.completions,
                          origin: CGPoint(x: placement.origin.x + (placement.walletLeading ? 42 : width - 42),
                                          y: placement.origin.y + unitHeight - 60))

            if let touch = session.touch {
                TourTouchRing(touch: touch)
            }

            if session.isConfirmingSkip {
                TourSkipConfirm(session: session)
                    .frame(width: size.width, height: size.height)
                    .transition(.opacity)
            }
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .animation(.easeInOut(duration: 0.2), value: session.isConfirmingSkip)
    }
}

private struct TourFrames {
    let registry: TourTargetRegistry
    let origin: CGPoint
    let size: CGSize
    let safeTop: CGFloat

    func frame(for target: TourTarget) -> TourTargetFrame? {
        if let chrome = TourSystemChrome.frame(for: target, size: size, safeTop: safeTop) {
            return chrome
        }
        guard let frame = registry.frames[target] else { return nil }
        return TourTargetFrame(rect: frame.rect.offsetBy(dx: -origin.x, dy: -origin.y), radius: frame.radius)
    }
}
