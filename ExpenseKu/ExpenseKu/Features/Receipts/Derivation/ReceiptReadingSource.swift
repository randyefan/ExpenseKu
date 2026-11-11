//
//  ReceiptReadingSource.swift
//  ExpenseKu
//
//  Who read a receipt: Gemma, the AI model, or OCR and the code rules, which are not AI —
//  and, for OCR, whether there was no model to ask or the model answered nothing usable
//  (docs/prd/reading-source.md §4.1). Its raw value is what an expense keeps (§4.3).
//

import Foundation

nonisolated enum ReceiptReadingSource: String, Codable, Sendable, Hashable {
    case gemma
    case ocrNoModel
    case ocrModelFailed

    var isAI: Bool { self == .gemma }

    /// Only a reading made without the model points at the download, and only while
    /// there is still something to download (§4.2).
    func offersDownload(modelIsReady: Bool) -> Bool {
        self == .ocrNoModel && !modelIsReady
    }

    var title: String {
        AppLocalization.string(isAI ? .readByGemmaAI : .readByOCRNoAI)
    }

    func caption(modelIsReady: Bool) -> String {
        switch self {
        case .gemma:
            AppLocalization.string(.gemmaReadingCaption)
        case .ocrNoModel where offersDownload(modelIsReady: modelIsReady):
            AppLocalization.string(.ocrNoModelDownloadCaption)
        case .ocrNoModel:
            AppLocalization.string(.ocrNoModelCaption)
        case .ocrModelFailed:
            AppLocalization.string(.ocrModelFailedCaption)
        }
    }

    /// The To check sheet's tag, which drops the reason (§4.4).
    var tag: String {
        AppLocalization.string(isAI ? .gemmaAI : .ocrNoAI)
    }

    var systemImage: String {
        isAI ? "sparkles" : "text.viewfinder"
    }
}
