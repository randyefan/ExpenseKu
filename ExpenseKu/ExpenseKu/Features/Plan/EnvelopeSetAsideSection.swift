//
//  EnvelopeSetAsideSection.swift
//  ExpenseKu
//
//  The last section of an envelope's detail (docs/prd/set-aside.md §4.7, frame W9): the
//  set-aside lines of earlier plans that fund it. Read only — each line belongs to
//  another cycle's plan, so its check is a face here, not a control.
//

import SwiftUI

struct EnvelopeSetAsideSection: View {
    let lines: [PlanItem]
    let payday: Int
    let calendar: Calendar

    var body: some View {
        Section {
            ForEach(lines) { line in
                HStack(spacing: 12) {
                    DoneCheckFace(state: .state(for: line))
                        .frame(width: 30, height: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(cycleTitle(of: line))
                            .font(.dsBody).bold()
                            .foregroundStyle(Theme.text)
                        Text(detail(of: line))
                            .font(.dsCaption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer(minLength: 8)
                    MoneyText(line.amount, font: .dsBody, color: Theme.text)
                        .layoutPriority(1)
                }
                .padding(.vertical, 6)
                .listRowBackground(Theme.card)
                .accessibilityElement(children: .combine)
            }
        } header: {
            SectionHeaderText("Set aside")
                .textCase(nil)
                .listRowInsets(EdgeInsets(top: 14, leading: 4, bottom: 6, trailing: 4))
        }
    }

    private func cycleTitle(of line: PlanItem) -> String {
        guard let start = line.plan?.cycleStart else { return "" }
        return PayCycle.containing(start, payday: payday, calendar: calendar).title(calendar: calendar)
    }

    private func detail(of line: PlanItem) -> String {
        let moved = line.isSetAsideMoved ? "moved" : "not moved yet"
        guard let account = line.account?.name else { return moved.prefix(1).uppercased() + moved.dropFirst() }
        return "\(account) · \(moved)"
    }
}
