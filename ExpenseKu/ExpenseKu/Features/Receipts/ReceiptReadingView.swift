//
//  ReceiptReadingView.swift
//  ExpenseKu
//
//  Manage → Receipt reading (docs/prd/receipt-reading.md §4.10, frame AG9): what it does,
//  the model card, and what happens without the model. Downloading on cellular asks first.
//

import SwiftUI

struct ReceiptReadingView: View {
    @Environment(ReceiptModelStore.self) private var store
    @State private var askingCellular = false
    @State private var askingRemove = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metric.cardGap) {
                VStack(spacing: 10) {
                    CategoryIcon(symbol: "text.viewfinder", tint: Theme.accent, size: 56)
                    Text("Fill expenses from receipts")
                        .font(.dsHeadline).bold()
                        .foregroundStyle(Theme.text)
                    Text("Reads a receipt on this iPhone and fills the amount, date, account, note and category. Nothing leaves the phone.")
                        .font(.dsSubhead)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .cardStyle(padding: 20)

                SectionHeaderText("Model")
                    .padding(.horizontal, 4)
                    .padding(.top, 10)

                ReceiptModelCard(
                    phase: store.phase,
                    onDownload: startDownload,
                    onPause: store.pause,
                    onRemove: { askingRemove = true }
                )

                Text("Until the model is here, receipts are read with simpler rules: amount, date and bank when they are clear. A broken download resumes from where it stopped.")
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 4)
            }
            .padding(Metric.screenPadding)
            .readableColumn()
        }
        .background(Theme.bg)
        .navigationTitle("Receipt reading")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Download 3.6 GB over cellular?", isPresented: $askingCellular) {
            Button("Cancel", role: .cancel) {}
            Button("Download") { store.download(allowingCellular: true) }
        } message: {
            Text("You are not on Wi-Fi. The download resumes if it is interrupted.")
        }
        .alert("Remove the model?", isPresented: $askingRemove) {
            Button("Remove", role: .destructive, action: store.remove)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Receipts will be read with simpler rules.")
        }
    }

    private func startDownload() {
        if store.isOnCellular {
            askingCellular = true
        } else {
            store.download(allowingCellular: false)
        }
    }
}
