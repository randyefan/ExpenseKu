//
//  ReceiptInboxCaption.swift
//  ExpenseKu
//
//  The inbox banner's caption while receipts are read ahead (docs/prd/receipt-reading.md
//  §4.11, frames AG10 and AG11). The title stays "N receipts waiting" throughout.
//

import Foundation

nonisolated enum ReceiptInboxCaption: Hashable {
    case shared
    case reading(ReadAheadProgress)
    case ready

    static func make(waiting: [ReceiptInboxItem], readIDs: Set<String>, progress: ReadAheadProgress?) -> Self {
        if let progress { return .reading(progress) }
        if !waiting.isEmpty, waiting.allSatisfy({ readIDs.contains($0.id) }) { return .ready }
        return .shared
    }
}
