//
//  StoredReceiptReading.swift
//  ExpenseKu
//
//  A waiting receipt's reading, kept beside it in the inbox so it is read once
//  (docs/prd/receipt-reading.md §4.11). One read without the model is read again once the
//  model is ready; one the model was asked for is not, even when the rules answered.
//  `source` is nil in a reading kept before docs/prd/reading-source.md, which then shows
//  no source.
//

import Foundation

nonisolated struct StoredReceiptReading: Codable, Sendable, Hashable {
    var reading: ReceiptReading
    var hadModel: Bool
    var source: ReceiptReadingSource?

    /// The source the form shows: none for a reading that filled nothing (§4.1).
    var shownSource: ReceiptReadingSource? {
        reading.isEmpty ? nil : source
    }
}
