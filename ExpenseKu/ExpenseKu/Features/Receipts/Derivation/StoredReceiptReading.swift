//
//  StoredReceiptReading.swift
//  ExpenseKu
//
//  A waiting receipt's reading, kept beside it in the inbox so it is read once
//  (docs/prd/receipt-reading.md §4.11). One read without the model is read again once the
//  model is ready. An older analysis is refreshed once for the description prompt;
//  current analyses are kept even when the model failed and the rules answered.
//  `source` is nil in a reading kept before docs/prd/reading-source.md, which then shows
//  no source.
//

import Foundation

nonisolated struct StoredReceiptReading: Codable, Sendable, Hashable {
    static let currentAnalysisVersion = 4

    var reading: ReceiptReading
    var hadModel: Bool
    var source: ReceiptReadingSource?
    var analysisVersion: Int? = currentAnalysisVersion

    /// The source the form shows: none for a reading that filled nothing (§4.1).
    var shownSource: ReceiptReadingSource? {
        reading.isEmpty ? nil : source
    }
}
