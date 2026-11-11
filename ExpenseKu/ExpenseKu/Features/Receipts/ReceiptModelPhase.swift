//
//  ReceiptModelPhase.swift
//  ExpenseKu
//
//  Where the model is on this iPhone (docs/prd/receipt-reading.md §4.10), and what the
//  Manage row says about it.
//

import Foundation

enum ReceiptModelPhase: Equatable {
    case notDownloaded
    case downloading(received: Int64, total: Int64)
    case paused(received: Int64, total: Int64, error: String?)
    case ready

    var fraction: Double {
        switch self {
        case .downloading(let received, let total), .paused(let received, let total, _):
            total > 0 ? Double(received) / Double(total) : 0
        case .notDownloaded: 0
        case .ready: 1
        }
    }

    var subtitle: String {
        switch self {
        case .notDownloaded:
            AppLocalization.string(.modelNotDownloaded)
        case .downloading(let received, let total):
            AppLocalization.string(.modelDownloadProgress(fraction.formatted(.percent.precision(.fractionLength(0)).locale(AppLocalization.locale)), Self.gigabytes(received), Self.gigabytes(total)))
        case .paused:
            AppLocalization.string(.pausedAt(fraction.formatted(.percent.precision(.fractionLength(0)).locale(AppLocalization.locale))))
        case .ready:
            AppLocalization.string(.receiptModelReady)
        }
    }

    static func gigabytes(_ bytes: Int64) -> String {
        (Double(bytes) / 1_000_000_000).formatted(.number.precision(.fractionLength(1)).locale(AppLocalization.locale)) + " GB"
    }
}
