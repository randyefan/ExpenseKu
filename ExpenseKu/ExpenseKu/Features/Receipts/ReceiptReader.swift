//
//  ReceiptReader.swift
//  ExpenseKu
//
//  One reading: OCR, candidates, then the model's grounded answer, or the rules when
//  there is no model or it answers nothing usable. The owner is never told which path
//  read the receipt (docs/prd/receipt-reading.md §4.9).
//

import Foundation

nonisolated struct ReceiptReader: Sendable {
    let model: (any ReceiptModel)?

    func read(_ data: Data, categories: [String]) async throws -> ReceiptReading {
        try await reading(of: data, categories: categories).reading
    }

    func reading(of data: Data, categories: [String]) async throws -> StoredReceiptReading {
        let text = try await ReceiptOCR.read(data)
        let candidates = CandidateExtractor.extract(from: text)
        if let model {
            let prompt = ExtractionPrompt.make(receipt: text, candidates: candidates, categories: categories)
            if let answer = try? await model.answer(prompt) {
                let reading = ReceiptResolver.resolve(answer: answer, receipt: text, candidates: candidates,
                                                      categories: categories)
                if !reading.isEmpty { return StoredReceiptReading(reading: reading, hadModel: true) }
            }
        }
        return StoredReceiptReading(reading: ReceiptRules.read(text, candidates: candidates), hadModel: model != nil)
    }
}
