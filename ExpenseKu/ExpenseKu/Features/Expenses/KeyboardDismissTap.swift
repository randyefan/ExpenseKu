//
//  KeyboardDismissTap.swift
//  ExpenseKu
//
//  Tap-outside-to-dismiss for the expense editor's notes keyboard. SwiftUI's `List`
//  offers interactive drag-dismissal but no tap-outside dismissal, so this installs a
//  recognizer on the enclosing window. Kept as its own file because it is the app's
//  only UIKit shim on this screen.
//

import SwiftUI

extension View {
    /// Dismisses the keyboard when the user taps anywhere outside a text input.
    func dismissesKeyboardOnOutsideTap() -> some View {
        background(KeyboardDismissTap())
    }
}

/// Installs a tap recognizer on the enclosing window that resigns the first
/// responder. `cancelsTouchesInView = false` so it never swallows a tap (buttons
/// and rows still work); its delegate ignores taps that land on a text field so
/// tapping the note to reposition the cursor keeps the keyboard up.
private struct KeyboardDismissTap: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Runs once the view is in a window, which `makeUIView` cannot guarantee.
        context.coordinator.install(from: uiView)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var window: UIWindow?
        private var recognizer: UITapGestureRecognizer?

        func install(from view: UIView) {
            guard recognizer == nil, let window = view.window else { return }
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            tap.cancelsTouchesInView = false
            tap.delegate = self
            window.addGestureRecognizer(tap)
            self.recognizer = tap
            self.window = window
        }

        func uninstall() {
            if let recognizer { window?.removeGestureRecognizer(recognizer) }
            recognizer = nil
            window = nil
        }

        @objc private func handleTap() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
            )
        }

        // Don't dismiss when the tap lands on (or inside) a text input — let the
        // field handle it so cursor placement doesn't drop the keyboard.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch
        ) -> Bool {
            var view = touch.view
            while let current = view {
                if current is UITextField || current is UITextView || current is UIControl {
                    return false
                }
                view = current.superview
            }
            return true
        }

        // Coexist with the list's own scroll/selection gestures.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool { true }
    }
}
