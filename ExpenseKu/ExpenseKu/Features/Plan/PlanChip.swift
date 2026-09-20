//
//  PlanChip.swift
//  ExpenseKu
//
//  The small capsules on a plan row's second line: what it is for, where it is paid
//  from, when it is due, and whether it posts itself.
//
//  They live on their own line because an IDR amount and a row of chips cannot share
//  402pt — the same trap the entity editors hit. A chip is quiet by default; only the
//  two that want acting on, `dueSoon` and `review`, take the accent.
//

import SwiftUI

struct PlanChip: View {
    enum Kind: Equatable {
        case category(tint: Color)
        case account
        case due
        case dueSoon
        case auto
        /// An Auto expense written without confirmation (ADR-0007).
        case review
    }

    let kind: Kind
    let text: String
    var symbol: String?

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .semibold))
            }
            Text(text)
                .font(.dsCaption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(background, in: .capsule)
        // One element, one label: without this the glyph and the text both report
        // themselves and every chip reads twice ("Cicilan, Cicilan").
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }

    private var foreground: Color {
        switch kind {
        case .category(let tint): tint
        case .account: Theme.textSecondary
        case .due: Theme.textSecondary
        case .dueSoon, .auto: Theme.accentText
        case .review: Theme.onAccent
        }
    }

    private var background: Color {
        switch kind {
        case .category(let tint): tint.opacity(Theme.tintFillOpacity)
        case .account, .due: Theme.textSecondary.opacity(0.12)
        case .dueSoon, .auto: Theme.accent.opacity(Theme.tintFillOpacity)
        case .review: Theme.accent
        }
    }
}
