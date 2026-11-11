import XCTest
import SwiftUI
import Vision
@testable import ExpenseKu

nonisolated final class ExpenseRowLayoutTests: XCTestCase {
    @MainActor
    func testShortAccountNameUsesItsIntrinsicWidth() throws {
        AppFont.registerIfNeeded()
        let label = ImageRenderer(content: ExpenseAccountLabel(account: Account(name: "Danamon")))
        let text = ImageRenderer(content: Text("Danamon").font(.dsCaption))
        label.proposedSize = ProposedViewSize(width: 300, height: nil)
        text.proposedSize = ProposedViewSize(width: 300, height: nil)

        let labelImage = try XCTUnwrap(label.cgImage)
        let textImage = try XCTUnwrap(text.cgImage)

        XCTAssertEqual(labelImage.width, textImage.width)
    }

    @MainActor
    func testLongAccountNameRemainsCapped() throws {
        let label = ImageRenderer(content: ExpenseAccountLabel(
            account: Account(name: "A very long account name for a bank")
        ))

        XCTAssertLessThanOrEqual(try XCTUnwrap(label.cgImage).width, 130)
    }

    @MainActor
    func testReceiptCheckTagStaysOnOneLineWhenCompressed() throws {
        let ideal = ImageRenderer(content: ReceiptCheckTag().environment(\.locale, Locale(identifier: "id_ID")))
        let compressed = ImageRenderer(content: ReceiptCheckTag().environment(\.locale, Locale(identifier: "id_ID")))
        compressed.proposedSize = ProposedViewSize(width: 36, height: nil)

        XCTAssertEqual(try XCTUnwrap(compressed.cgImage).height, try XCTUnwrap(ideal.cgImage).height)
    }

    @MainActor
    func testReceiptRowShowsCategoryAndCheckWhenTheyFitBeforeTheAmount() throws {
        AppFont.registerIfNeeded()
        let expense = Expense(
            amount: 37_800, note: "makanan kucing janda", category: Category(name: "Kucing"),
            account: Account(name: "Danamon"), needsReview: true
        )
        expense.receiptImage = Data([0xFF, 0xD8])
        let renderer = ImageRenderer(content: ExpenseRow(expense: expense)
            .frame(width: 329)
            .padding(16)
            .background(Theme.card)
            .environment(\.locale, Locale(identifier: "id_ID"))
            .environment(\.colorScheme, .dark))
        renderer.scale = 3
        let image = try XCTUnwrap(renderer.cgImage)
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        try VNImageRequestHandler(cgImage: image).perform([request])
        let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")

        XCTAssertTrue(text.contains("Kucing"), text)
        XCTAssertTrue(text.contains("Check"), text)
        XCTAssertTrue(text.contains("37.800"), text)
        let attachment = XCTAttachment(image: try XCTUnwrap(renderer.uiImage))
        attachment.name = "Receipt row"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
