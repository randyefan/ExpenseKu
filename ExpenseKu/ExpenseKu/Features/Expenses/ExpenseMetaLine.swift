//
//  ExpenseMetaLine.swift
//  ExpenseKu
//
//  The quiet grey line under an expense's category: the note and who was there, on
//  one line separated by middots. One line rather than two, so a day's worth of
//  expenses fits on screen together. The Account sits under the amount instead
//  (docs/prd/bank-logos.md §5.5).
//

import SwiftUI

struct ExpenseMetaLine: View {
    let note: String
    let peopleNames: String

    private var parts: [String] {
        var parts: [String] = []
        if !note.isEmpty { parts.append(note) }
        if !peopleNames.isEmpty { parts.append(peopleNames) }
        return parts
    }

    var body: some View {
        if !parts.isEmpty {
            Text(parts.joined(separator: "\u{00A0}· "))
                .font(.dsCaption)
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(6)
                .truncationMode(.tail)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        ExpenseMetaLine(note: "Dinner", peopleNames: "Tarisa & Fadil")
        ExpenseMetaLine(note: "", peopleNames: "Tarisa")
        ExpenseMetaLine(note: "A note long enough that it has to be truncated somewhere",
                        peopleNames: "Tarisa, Fadil & Budi")
    }
    .padding()
    .appBackground()
}
