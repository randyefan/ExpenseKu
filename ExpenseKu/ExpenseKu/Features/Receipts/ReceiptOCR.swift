//
//  ReceiptOCR.swift
//  ExpenseKu
//
//  Vision's text recognition, in Indonesian and English, grouped into rows. Phone shots
//  and screenshots are often a few degrees off, so rows are levelled by the median slope
//  of the widest third of the text first: short words alone tilt too noisily, and without
//  levelling a label and its value land on different rows (found in the spike).
//

import Foundation
import PDFKit
import UIKit
import Vision

nonisolated enum ReceiptOCR {
    private struct Fragment {
        let text: String
        let midX: CGFloat
        let midY: CGFloat
        let minX: CGFloat
        let width: CGFloat
        let height: CGFloat
        let slope: CGFloat
    }

    static func read(_ data: Data) async throws -> ReceiptText {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = [Locale.Language(identifier: "id"), Locale.Language(identifier: "en")]
        let observations = try await request.perform(on: imageData(from: data))
        return ReceiptText(rows: rows(from: observations.compactMap(fragment)))
    }

    /// A PDF is read from its first page (§4.1).
    static func imageData(from data: Data) -> Data {
        guard data.starts(with: Array("%PDF".utf8)), let page = PDFDocument(data: data)?.page(at: 0) else {
            return data
        }
        let bounds = page.bounds(for: .mediaBox)
        let scale = 2200 / max(bounds.width, bounds.height, 1)
        let image = page.thumbnail(of: CGSize(width: bounds.width * scale, height: bounds.height * scale), for: .mediaBox)
        return image.pngData() ?? data
    }

    private static func fragment(_ observation: RecognizedTextObservation) -> Fragment? {
        guard let candidate = observation.topCandidates(1).first else { return nil }
        let box = observation.boundingBox.cgRect
        let left = observation.bottomLeft.cgPoint
        let right = observation.bottomRight.cgPoint
        let run = right.x - left.x
        let textHeight = abs(observation.topLeft.cgPoint.y - left.y)
        return Fragment(
            text: candidate.string,
            midX: box.midX,
            midY: box.midY,
            minX: box.minX,
            width: run,
            height: textHeight > 0 ? textHeight : box.height,
            slope: run > 0 ? (right.y - left.y) / run : 0
        )
    }

    private static func rows(from fragments: [Fragment]) -> [[TextSpan]] {
        let widest = fragments.sorted { $0.width > $1.width }.prefix(max(3, fragments.count / 3))
        let slopes = widest.map(\.slope).sorted()
        let slope = slopes.isEmpty ? 0 : slopes[slopes.count / 2]
        func level(_ fragment: Fragment) -> CGFloat { fragment.midY - slope * fragment.midX }

        var grouped: [[Fragment]] = []
        for fragment in fragments.sorted(by: { level($0) > level($1) }) {
            if let anchor = grouped.last?.first,
               abs(level(anchor) - level(fragment)) < min(anchor.height, fragment.height) * 0.5 {
                grouped[grouped.count - 1].append(fragment)
            } else {
                grouped.append([fragment])
            }
        }

        var next = 1
        return grouped.map { row in
            row.sorted { $0.minX < $1.minX }.map { fragment in
                defer { next += 1 }
                return TextSpan(id: "S\(next)", text: fragment.text)
            }
        }
    }
}
