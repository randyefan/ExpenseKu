//
//  PlanRowTitleLine.swift
//  ExpenseKu
//

import SwiftUI

/// The top of a plan row's name line. Done aligns to it rather than to the row's top,
/// so a plan-was caption above the amount does not leave Done stranded above the name.
extension VerticalAlignment {
    private enum PlanRowTitleLine: AlignmentID {
        static func defaultValue(in dimensions: ViewDimensions) -> CGFloat { dimensions[.top] }
    }

    static let planRowTitleLine = VerticalAlignment(PlanRowTitleLine.self)
}
