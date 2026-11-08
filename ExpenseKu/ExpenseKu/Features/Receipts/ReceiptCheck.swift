//
//  ReceiptCheck.swift
//  ExpenseKu
//
//  An expense saved from a receipt and not yet checked (docs/prd/receipt-reading.md §4.7).
//  Told apart from an Auto item's Needs review by having no plan item (ADR-0014); that
//  one is still reviewed in the Plan lens.
//

import Foundation

extension Expense {
    var isReceiptToCheck: Bool { needsReview && planItem == nil }

    /// Checking clears the flag and deletes the image together.
    func markReceiptChecked() {
        needsReview = false
        receiptImage = nil
    }
}
