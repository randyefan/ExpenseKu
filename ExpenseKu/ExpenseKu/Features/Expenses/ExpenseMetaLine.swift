//
//  ExpenseMetaLine.swift
//  ExpenseKu
//
//  The quiet grey line under an expense's category: the note, which account it came
//  from and who was there, on one line separated by middots. One line rather than
//  three, so a day's worth of expenses fits on screen together.
//

import SwiftUI

struct ExpenseMetaLine: View {
    let note: String
    let accountName: String?
    let peopleNames: String
    var origin: PlanOrigin? = nil

    private var parts: [String] {
        var parts: [String] = []
        if !note.isEmpty { parts.append(note) }
        if let accountName, !accountName.isEmpty { parts.append(accountName) }
        if !peopleNames.isEmpty { parts.append(peopleNames) }
        return parts
    }

    var body: some View {
        if let origin {
            HStack(spacing: 6) {
                PlanOriginTag(origin: origin)
                    .layoutPriority(1)
                text
            }
        } else {
            text
        }
    }

    @ViewBuilder
    private var text: some View {
        if !parts.isEmpty {
            Text(parts.joined(separator: " · "))
                .font(.dsCaption)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        ExpenseMetaLine(note: "Dinner", accountName: "GoPay", peopleNames: "Tarisa & Fadil")
        ExpenseMetaLine(note: "", accountName: "Cash", peopleNames: "")
        ExpenseMetaLine(note: "A note long enough that it has to be truncated somewhere",
                        accountName: "Bank Central Asia", peopleNames: "Tarisa, Fadil & Budi")
        ExpenseMetaLine(note: "Kos", accountName: "BCA", peopleNames: "", origin: .fixed)
        ExpenseMetaLine(note: "Dinner", accountName: "GoPay", peopleNames: "Tarisa & Fadil",
                        origin: .envelope(name: "Hidup"))
    }
    .padding()
    .appBackground()
}
