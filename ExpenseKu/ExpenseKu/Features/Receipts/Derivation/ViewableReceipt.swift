//
//  ViewableReceipt.swift
//  ExpenseKu
//
//  The receipt the expense form can show (docs/prd/receipt-reading.md §4.3.1, frame AG12):
//  the one a reading just filled it from, else the image an expense still to check keeps.
//

import Foundation

nonisolated enum ViewableReceipt {
    static func image(filledFrom filled: Data?, saved: Data?, savedIsToCheck: Bool) -> Data? {
        filled ?? (savedIsToCheck ? saved : nil)
    }
}
