//
//  ReceiptReader.swift
//  ExpenseKu
//
//  One reading: OCR, candidates, then the model's grounded answer, or the rules when
//  there is no model or it answers nothing usable. The reading says which of the three
//  happened (docs/prd/reading-source.md §4.1).
//

import Foundation

nonisolated struct ReceiptReader: Sendable {
    let model: (any ReceiptModel)?

    @concurrent
    func reading(of data: Data, categories: [String]) async throws -> StoredReceiptReading {
        let text = try await ReceiptOCR.read(data)
        let candidates = CandidateExtractor.extract(from: text)
        var answer: String?
        if let model {
            let prompt = ExtractionPrompt.make(receipt: text, candidates: candidates, categories: categories)
            answer = try? await model.answer(prompt)
        }
        return Self.reading(of: text, candidates: candidates, categories: categories,
                            hadModel: model != nil, answer: answer)
    }

    static func reading(of text: ReceiptText, candidates: ReceiptCandidates, categories: [String],
                        hadModel: Bool, answer: String?) -> StoredReceiptReading {
        if let answer {
            let reading = ReceiptResolver.resolve(answer: answer, receipt: text, candidates: candidates,
                                                  categories: categories)
            if !reading.isEmpty { return StoredReceiptReading(reading: reading, hadModel: true, source: .gemma) }
        }
        return StoredReceiptReading(reading: ReceiptRules.read(text, candidates: candidates), hadModel: hadModel,
                                    source: hadModel ? .ocrModelFailed : .ocrNoModel)
    }
}
