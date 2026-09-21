//
//  DiscardChangesGuard.swift
//  ExpenseKu
//
//  Stops a swipe-down from silently throwing away a half-filled editor sheet. SwiftUI
//  can block the swipe with `interactiveDismissDisabled`, but has no callback for the
//  blocked attempt, so the alert hangs off UIKit's
//  `presentationControllerDidAttemptToDismiss` instead.
//

import SwiftUI

extension View {
    /// While `hasChanges` is true, a swipe-down on the enclosing sheet asks before
    /// leaving; confirming calls `onDiscard`, which is expected to dismiss.
    func confirmsDiscard(when hasChanges: Bool, onDiscard: @escaping () -> Void) -> some View {
        modifier(DiscardChangesGuard(hasChanges: hasChanges, onDiscard: onDiscard))
    }
}

private struct DiscardChangesGuard: ViewModifier {
    let hasChanges: Bool
    let onDiscard: () -> Void

    @State private var isAsking = false

    func body(content: Content) -> some View {
        content
            .interactiveDismissDisabled(hasChanges)
            .background(DismissAttemptObserver { isAsking = true })
            .alert("Are you sure you want to quit?", isPresented: $isAsking) {
                Button("Yes", role: .destructive, action: onDiscard)
                Button("No", role: .cancel) {}
            } message: {
                Text("What you've filled in so far will be lost.")
            }
    }
}

private struct DismissAttemptObserver: UIViewControllerRepresentable {
    let onAttempt: () -> Void

    func makeUIViewController(context: Context) -> ObserverController {
        ObserverController(onAttempt: onAttempt)
    }

    func updateUIViewController(_ controller: ObserverController, context: Context) {
        controller.onAttempt = onAttempt
    }

    static func dismantleUIViewController(_ controller: ObserverController, coordinator: ()) {
        controller.uninstall()
    }

    final class ObserverController: UIViewController {
        var onAttempt: () -> Void
        private var proxy: DelegateProxy?

        init(onAttempt: @escaping () -> Void) {
            self.onAttempt = onAttempt
            super.init(nibName: nil, bundle: nil)
            view.isUserInteractionEnabled = false
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            install()
        }

        private func install() {
            var top: UIViewController = self
            while let parent = top.parent { top = parent }
            guard top.presentingViewController != nil,
                  let presentation = top.presentationController,
                  presentation.delegate !== proxy
            else { return }
            let proxy = DelegateProxy(forwardingTo: presentation.delegate) { [weak self] in
                self?.onAttempt()
            }
            proxy.presentation = presentation
            presentation.delegate = proxy
            self.proxy = proxy
        }

        func uninstall() {
            guard let proxy, let presentation = proxy.presentation else { return }
            if presentation.delegate === proxy { presentation.delegate = proxy.original }
            self.proxy = nil
        }
    }
}

/// SwiftUI owns the sheet's delegate and uses it to reset the `isPresented`/`item`
/// binding, so it is wrapped rather than replaced: every other call is forwarded.
private final class DelegateProxy: NSObject, UIAdaptivePresentationControllerDelegate {
    weak var original: (any UIAdaptivePresentationControllerDelegate)?
    weak var presentation: UIPresentationController?
    private let onAttempt: () -> Void

    init(forwardingTo original: (any UIAdaptivePresentationControllerDelegate)?,
         onAttempt: @escaping () -> Void) {
        self.original = original
        self.onAttempt = onAttempt
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        original?.presentationControllerDidAttemptToDismiss?(presentationController)
        onAttempt()
    }

    nonisolated override func responds(to selector: Selector!) -> Bool {
        super.responds(to: selector) || MainActor.assumeIsolated { original?.responds(to: selector) ?? false }
    }

    nonisolated override func forwardingTarget(for selector: Selector!) -> Any? {
        let original = MainActor.assumeIsolated { self.original }
        return original?.responds(to: selector) == true ? original : super.forwardingTarget(for: selector)
    }
}
