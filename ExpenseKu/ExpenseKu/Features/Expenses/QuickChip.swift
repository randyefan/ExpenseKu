//
//  QuickChip.swift
//  ExpenseKu
//

import SwiftUI

struct QuickChip<Lead: View>: View {
    let title: String
    let isSelected: Bool
    var isMuted = false
    let action: () -> Void
    @ViewBuilder var lead: Lead

    var body: some View {
        Button(action: action) {
            QuickChipLabel(title: title, isSelected: isSelected, isMuted: isMuted) { lead }
        }
        .buttonStyle(.pressableCard)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension QuickChip where Lead == EmptyView {
    init(title: String, isSelected: Bool, isMuted: Bool = false, action: @escaping () -> Void) {
        self.init(title: title, isSelected: isSelected, isMuted: isMuted, action: action) { EmptyView() }
    }
}
