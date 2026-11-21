//
//  Theme+Tour.swift
//  ExpenseKu
//
//  The five tour-* tokens of Flow AO (welcome-tour.md decision 29): a light bubble on a 72 %
//  black scrim, so the guide reads as something apart from the app it points at.
//

import SwiftUI

extension Theme {
    static let tourScrim = Color.black.opacity(0.72)
    static let tourBubble = Color(hex: 0xF2F3F5)
    static let tourBubbleText = Color(hex: 0x14161A)
    static let tourBubbleMuted = Color(hex: 0x5A5F66)
    static let tourTrack = Color(hex: 0x14161A).opacity(0.15)
}
