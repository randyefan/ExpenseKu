//
//  ReceiptModelRuntime.swift
//  ExpenseKu
//
//  Whether Gemma can run here, and how it is made. MLX cannot run in the iOS Simulator:
//  its first GPU stream dereferences a null Metal architecture name, and forcing the CPU
//  comes too late (found in the spike). There the rules read every receipt.
//

import Foundation

enum ReceiptModelRuntime {
    static var canRun: Bool {
        #if targetEnvironment(simulator)
        false
        #else
        GemmaReceiptModel.isAvailable
        #endif
    }

    static func make(directory: URL) -> (any ReceiptModel)? {
        GemmaReceiptModel.isAvailable ? GemmaReceiptModel(directory: directory) : nil
    }
}
