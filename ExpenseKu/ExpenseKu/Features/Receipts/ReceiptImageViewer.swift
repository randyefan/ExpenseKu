//
//  ReceiptImageViewer.swift
//  ExpenseKu
//
//  A receipt full screen, pinch to zoom and drag to move while zoomed
//  (docs/prd/receipt-reading.md §4.3.1, §4.8).
//

import SwiftUI

struct ReceiptImageViewer: View {
    let data: Data

    @Environment(\.dismiss) private var dismiss
    @State private var zoom: CGFloat = 1
    @GestureState private var pinch: CGFloat = 1
    @State private var offset: CGSize = .zero
    @GestureState private var drag: CGSize = .zero

    var body: some View {
        NavigationStack {
            Group {
                if let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(zoom * pinch)
                        .offset(x: offset.width + drag.width, y: offset.height + drag.height)
                        .gesture(
                            MagnifyGesture()
                                .updating($pinch) { value, state, _ in state = value.magnification }
                                .onEnded { value in
                                    zoom = min(max(zoom * value.magnification, 1), 5)
                                    if zoom == 1 { offset = .zero }
                                }
                                .simultaneously(with: DragGesture()
                                    .updating($drag) { value, state, _ in
                                        if zoom > 1 { state = value.translation }
                                    }
                                    .onEnded { value in
                                        guard zoom > 1 else { return }
                                        offset.width += value.translation.width
                                        offset.height += value.translation.height
                                    }
                                )
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
