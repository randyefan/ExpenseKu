//
//  ShareViewController.swift
//  ExpenseKuShare
//
//  The share extension's entry point. iOS gives an extension a view controller, so this
//  one only hosts ShareSavedView and puts the shared file in the receipt inbox
//  (docs/prd/receipt-reading.md §4.1). It never opens the app: iOS has no supported way.
//

import SwiftUI
import UIKit

final class ShareViewController: UIViewController {
    private var host: UIHostingController<ShareSavedView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        show(.saving)
        let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        Task {
            guard let payload = await SharedReceipt.load(from: items),
                  (try? ReceiptInboxFolder.shared.add(payload.data, fileExtension: payload.fileExtension)) != nil
            else {
                show(.failed)
                return
            }
            show(.saved(UIImage(data: ReceiptOCRThumbnail.imageData(payload))))
        }
    }

    // iOS ignores an extension's own modalPresentationStyle and wraps it in a full-height
    // sheet whose views live in this process, which showed as an empty system-coloured
    // sheet behind the card. Its detents can't be changed from here, so it is cleared.
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        var container = view.superview
        while let current = container, !(current is UIWindow) {
            current.backgroundColor = .clear
            current.layer.shadowOpacity = 0
            container = current.superview
        }
    }

    private func show(_ state: ShareSavedView.State) {
        let root = ShareSavedView(state: state) { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
        if let host {
            host.rootView = root
            return
        }
        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .clear
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)
        self.host = host
    }
}
