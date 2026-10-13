//
//  EnvelopeBarLine.swift
//  ExpenseKu
//

import SwiftUI

/// The bottom of an envelope row's bar line. ＋ aligns to it rather than to the row's
/// bottom, so a paid-early caption under the bar does not pull ＋ down with it.
extension VerticalAlignment {
    private enum EnvelopeBarLine: AlignmentID {
        static func defaultValue(in dimensions: ViewDimensions) -> CGFloat { dimensions[.bottom] }
    }

    static let envelopeBarLine = VerticalAlignment(EnvelopeBarLine.self)
}
