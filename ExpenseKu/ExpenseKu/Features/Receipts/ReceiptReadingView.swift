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
                    Text(appLocalized: .fillExpensesFromReceipts)
                        .font(.dsHeadline).bold()
                        .foregroundStyle(Theme.text)
                    Text(appLocalized: .readsAReceiptOnThisIPhoneAndFillsTheAmountDate)
                        .font(.dsSubhead)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .cardStyle(padding: 20)

                SectionHeaderText(.model)
                    .padding(.horizontal, 4)
                    .padding(.top, 10)

                ReceiptModelCard(
                    phase: store.phase,
                    onDownload: startDownload,
                    onPause: store.pause,
                    onRemove: { askingRemove = true }
                )

                Text(appLocalized: .untilTheModelIsHereReceiptsAreReadWithSimplerRules)
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 4)
            }
            .padding(Metric.screenPadding)
            .readableColumn()
        }
        .background(Theme.bg)
        .navigationTitle(AppLocalization.string(.receiptReading))
        .navigationBarTitleDisplayMode(.inline)
        .alert(AppLocalization.string(.receiptModelCellularDownload), isPresented: $askingCellular) {
            Button(AppLocalization.string(.cancel), role: .cancel) {}
            Button(AppLocalization.string(.download)) { store.download(allowingCellular: true) }
        } message: {
            Text(appLocalized: .youAreNotOnWiFiTheDownloadResumesIfIt)
        }
        .alert(AppLocalization.string(.removeTheModel), isPresented: $askingRemove) {
            Button(AppLocalization.string(.remove), role: .destructive, action: store.remove)
            Button(AppLocalization.string(.cancel), role: .cancel) {}
        } message: {
            Text(appLocalized: .receiptsWillBeReadWithSimplerRules)
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
