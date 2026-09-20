//
//  AutoReviewSheet.swift
//  ExpenseKu
//
//  The Auto items that posted themselves, and what they actually wrote (frame I3).
//
//  ADR-0007 accepts that the app can record money that never moved: a failed autodebit
//  or a changed amount produces a confidently wrong Expense. The needs-review flag is
//  the only defence, and a flag that could only be dismissed would be no defence at
//  all — so every line opens in the ordinary expense editor, where a wrong figure is
//  corrected the same way every other figure is.
//
//  The footer clears every flag at once, because the common case after a few days away
//  is five correct items.
//

import SwiftUI
import SwiftData

struct AutoReviewSheet: View {
    let review: ReviewState
    let items: [PlanItem]
    let onOpenExpense: (Expense) -> Void
    let onFinish: () -> Void

    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        ForEach(items, id: \.persistentModelID) { item in
                            if let expense = item.linkedExpense, expense.needsReview {
                                Button { onOpenExpense(expense) } label: {
                                    row(item: item, expense: expense)
                                }
                                .buttonStyle(.pressableRow)
                                .listRowBackground(Theme.card)
                            }
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(review.title)
                                .font(.dsTitle).bold()
                                .foregroundStyle(Theme.text)
                            Text(review.detail)
                                .font(.dsCaption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .textCase(nil)
                        .padding(.bottom, 4)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                Button("All correct — clear the flags", action: clearAll)
                    .font(.dsBody).bold()
                    .foregroundStyle(Theme.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: .capsule)
                    .buttonStyle(.pressableCard)
                    .padding(.horizontal, Metric.screenPadding)
                    .padding(.bottom, 12)
            }
            .background(Theme.bg)
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onFinish).tint(Theme.accentText)
                }
            }
        }
    }

    private func row(item: PlanItem, expense: Expense) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Theme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name.isEmpty ? "Plan item" : item.name)
                    .font(.dsBody).bold()
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Text(expense.amount == item.amount
                     ? "matches the plan"
                     : "plan was \(item.amount.formattedIDR())")
                    .font(.dsCaption)
                    .foregroundStyle(expense.amount == item.amount ? Theme.textSecondary : Theme.negative)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            MoneyText(expense.amount, font: .dsBody, color: Theme.text)
                .layoutPriority(1)
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
    }

    private func clearAll() {
        for item in items {
            item.linkedExpense?.needsReview = false
        }
        try? context.save()
        onFinish()
    }
}
