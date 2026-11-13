//
//  ReadAheadPlan.swift
//  ExpenseKu
//
//  Which waiting receipts a foreground pass reads, oldest first
//  (docs/prd/receipt-reading.md §4.11): those with no reading, and those the rules read
//  once the model is ready.
//

import Foundation

nonisolated enum ReadAheadPlan {
    static func receiptsToRead(_ items: [ReceiptInboxItem], stored: [String: StoredReceiptReading],
                               modelIsReady: Bool) -> [ReceiptInboxItem] {
        items.filter { needsReading(stored[$0.id], modelIsReady: modelIsReady) }
    }

    static func needsReading(_ stored: StoredReceiptReading?, modelIsReady: Bool) -> Bool {
        guard let stored else { return true }
        return modelIsReady && (!stored.hadModel || stored.analysisVersion != StoredReceiptReading.currentAnalysisVersion)
    }
}
