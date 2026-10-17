//
//  BankLogoMark.swift
//  ExpenseKu — DesignSystem
//
//  A bank logo in a white circle the size of the CategoryIcon it stands in for
//  (docs/prd/bank-logos.md §5.1). Most bank logos are drawn for a white page, so on
//  the dark canvas they need their own; the logo itself is never tinted.
//
//  Hidden from VoiceOver: wherever it appears the Account's name is read beside it.
//

import SwiftUI

struct BankLogoMark: View {
    let logo: BankLogo
    var size: CGFloat = Metric.iconSize

    @Environment(BankLogoCatalog.self) private var catalog: BankLogoCatalog?

    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: size, height: size)
            .overlay {
                (catalog ?? .fallback).image(for: logo)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.19)
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        ForEach(BankLogo.snapshot.prefix(4)) { BankLogoMark(logo: $0) }
    }
    .padding()
    .appBackground()
}
