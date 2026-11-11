//
//  ReceiptReviewSheet.swift
//  ExpenseKu
//
//  "To check (N)": every receipt expense not yet checked, oldest first
//  (docs/prd/receipt-reading.md §4.8, frame AG7). Closes itself when the last card leaves.
//

import SwiftData
import SwiftUI

struct ReceiptReviewSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Expense> { $0.needsReview }, sort: \Expense.date)
    private var flagged: [Expense]

    @State private var editing: Expense?
    @State private var viewing: Expense?

    private var toCheck: [Expense] { flagged.filter(\.isReceiptToCheck) }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Metric.cardGap) {
                    ForEach(toCheck) { expense in
                        ReceiptCheckCard(
                            expense: expense,
                            onImage: { viewing = expense },
                            onEdit: { editing = expense },
                            onLooksRight: { check(expense) }
                        )
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                .padding(Metric.screenPadding)
            }
            .background(Theme.bg)
            .navigationTitle(AppLocalization.string(.toCheck(String(toCheck.count))))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.string(.close), systemImage: "xmark") { dismiss() }
                }
            }
            .onChange(of: toCheck.isEmpty) { _, isEmpty in
                if isEmpty, editing == nil { dismiss() }
            }
            .sheet(item: $editing) { expense in
                NavigationStack {
                    ExpenseEditorView(editing: expense, onFinish: { editing = nil })
                }
                .presentationBackground(Theme.bg)
            }
            .fullScreenCover(item: $viewing) { expense in
                if let data = expense.receiptImage {
                    ReceiptImageViewer(data: data)
                }
            }
        }
    }

    private func check(_ expense: Expense) {
        withAnimation(Motion.settle) {
            expense.markReceiptChecked()
            try? context.save()
        }
    }
}
