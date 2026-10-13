//
//  EnvelopeMoveSheet.swift
//  ExpenseKu
//
//  "Move N expenses" (frame Q8): the picker's choices for a whole selection. Nothing is
//  ticked, because the selection may be mixed, and picking applies at once — moving
//  again is the undo (envelope-assignment.md §4.6).
//

import SwiftUI

struct EnvelopeMoveSheet: View {
    let options: EnvelopeOptions
    let count: Int
    let onPick: (EnvelopeChoice) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            EnvelopeChoiceList(options: options,
                               chosen: nil,
                               byCategoryDetail: EnvelopeOptions.byCategoryDetailForMany) { choice in
                onPick(choice)
                dismiss()
            }
            .navigationTitle("Move \(PlanCopy.counted(count, "expense"))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
