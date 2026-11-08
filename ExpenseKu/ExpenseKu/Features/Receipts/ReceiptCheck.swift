//
//  ReceiptCheck.swift
//  ExpenseKu
//
//  An expense saved from a receipt and not yet checked (docs/prd/receipt-reading.md §4.7).
//  Told apart from an Auto item's Needs review by carrying its receipt (ADR-0014), not by
//  having no plan item: an Auto expense whose item was deleted keeps its flag too.
//

import Foundation

extension Expense {
    var isReceiptToCheck: Bool { needsReview && receiptImage != nil }

    /// Checking clears the flag and deletes the image together.
    func markReceiptChecked() {
        needsReview = false
        receiptImage = nil
    }
}
