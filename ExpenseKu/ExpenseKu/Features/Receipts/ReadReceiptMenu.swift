//
//  ReadReceiptMenu.swift
//  ExpenseKu
//
//  Read receipt in the expense form's navigation bar: Photos, Camera, Paste
//  (docs/prd/receipt-reading.md §4.3, frame AG3). Paste is offered only while the
//  pasteboard holds an image, and Camera only where the document camera exists.
//

import SwiftUI

struct ReadReceiptMenu: View {
    let onPhotos: () -> Void
    let onCamera: () -> Void
    let onPaste: () -> Void

    @State private var pasteboardHasImage = UIPasteboard.general.hasImages

    var body: some View {
        Menu("Read receipt", systemImage: "receipt") {
            Button("Photos", systemImage: "photo", action: onPhotos)
            Button("Camera", systemImage: "camera", action: onCamera)
                .disabled(!DocumentCameraView.isSupported)
            Button("Paste", systemImage: "doc.on.clipboard", action: onPaste)
                .disabled(!pasteboardHasImage)
        }
        .onAppear { pasteboardHasImage = UIPasteboard.general.hasImages }
        .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
            pasteboardHasImage = UIPasteboard.general.hasImages
        }
    }
}
