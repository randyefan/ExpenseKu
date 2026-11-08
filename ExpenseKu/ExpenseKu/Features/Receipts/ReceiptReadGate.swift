//
//  ReceiptReadGate.swift
//  ExpenseKu
//
//  One reading at a time, first come first served: the model holds gigabytes, and a form
//  waiting on its receipt must go before the next receipt the pass would read
//  (docs/prd/receipt-reading.md §4.11).
//

import Foundation

actor ReceiptReadGate {
    private var isBusy = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        guard isBusy else {
            isBusy = true
            return
        }
        await withCheckedContinuation { waiting.append($0) }
    }

    func release() {
        if waiting.isEmpty {
            isBusy = false
        } else {
            waiting.removeFirst().resume()
        }
    }
}
