//
//  Spacing.swift
//  ExpenseKu — DesignSystem
//
//  Layout rhythm for "Warm Cards": card radius 16, padding 16, inter-card gap 12.
//  Shape lock — cards 16, rows nested inside a card 12, controls are capsules.
//

import CoreGraphics

enum Metric {
    static let cardRadius: CGFloat = 16
    static let rowRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let cardGap: CGFloat = 12
    static let screenPadding: CGFloat = 16
    static let iconSize: CGFloat = 44
    static let rowIconSize: CGFloat = 38
    /// An expense row's leading mark: an Account's logo has to stay legible at it.
    static let rowMarkSize: CGFloat = 42
    /// The widest a single column of cards grows on iPad before it centres instead.
    static let readableWidth: CGFloat = 720
}
