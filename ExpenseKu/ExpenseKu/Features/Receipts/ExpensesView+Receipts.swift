//
//  ExpensesView+Receipts.swift
//  ExpenseKu
//
//  The Expenses tab's side of reading receipts: the banner counts, starting and
//  continuing the inbox run, and the review sheet (docs/prd/receipt-reading.md §4.2,
//  §4.5, §4.8). The next receipt opens from the finished sheet's onDismiss, because a
//  sheet presented while another is still animating away is dropped.
//

import SwiftUI

extension ExpensesView {
    func startReceiptRun() {
        receiptInbox.refresh()
        receiptRun = ReceiptRun.start(with: receiptInbox.items)
    }

    func endReceiptRun(_ run: ReceiptRun, _ outcome: ReceiptRun.Outcome) {
        if outcome != .later { receiptInbox.remove(run.item) }
        nextReceiptRun = outcome == .later ? nil : run.next(in: receiptInbox.items)
    }

    func continueReceiptRun() {
        receiptRun = nextReceiptRun
        nextReceiptRun = nil
    }
}
