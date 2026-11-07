//
//  QuickChipLabel.swift
//  ExpenseKu
//
//  The capsule every one-tap choice in the expense editor wears: an optional leading
//  mark, the name, and an amber outline on an amber wash when chosen. One look for
//  dates, People and the All… menu, so selection reads the same everywhere.
//

import SwiftUI

struct QuickChipLabel<Lead: View>: View {
    let title: String
    let isSelected: Bool
    var isMuted = false
    @ViewBuilder var lead: Lead

    var body: some View {
        HStack(spacing: 6) {
            lead
            Text(title)
                .font(.dsSubhead).fontWeight(.semibold)
                .foregroundStyle(isMuted ? Theme.textSecondary : Theme.text)
                .lineLimit(1)
        }
        .padding(.leading, Lead.self == EmptyView.self ? 14 : 4)
        .padding(.trailing, Lead.self == EmptyView.self ? 14 : 12)
        .padding(.vertical, Lead.self == EmptyView.self ? 8 : 4)
        .frame(minHeight: 36)
        .background {
            Capsule()
                .fill(isSelected ? Theme.accent.opacity(0.12) : Theme.card)
                .strokeBorder(isSelected ? Theme.accent : Theme.hairline, lineWidth: isSelected ? 1.5 : 1)
        }
        .contentShape(.capsule)
    }
}

extension QuickChipLabel where Lead == EmptyView {
    init(title: String, isSelected: Bool, isMuted: Bool = false) {
        self.init(title: title, isSelected: isSelected, isMuted: isMuted) { EmptyView() }
    }
}

#Preview {
    HStack {
        QuickChipLabel(title: "Now", isSelected: false)
        QuickChipLabel(title: "1h ago", isSelected: true)
        QuickChipLabel(title: "Tarisa", isSelected: true) {
            PersonAvatar(name: "Tarisa", size: 26)
        }
        QuickChipLabel(title: "All…", isSelected: false, isMuted: true)
    }
    .padding()
    .appBackground()
}
