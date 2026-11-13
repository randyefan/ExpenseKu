import CoreImage
import XCTest
@testable import ExpenseKu

nonisolated final class ReceiptImageInputTests: XCTestCase {
    func testReaderPassesReceiptImageAndOCRPromptToModel() async throws {
        let receipt = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 320, height: 320))
        let image = try XCTUnwrap(CIContext().pngRepresentation(
            of: receipt, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB()))
        let model = ReceiptImageModelProbe()

        let stored = try await ReceiptReader(model: model).reading(of: image, categories: ["Transfer"])
        let request = await model.request

        XCTAssertEqual(request?.image, image)
        XCTAssertTrue(request?.prompt.contains("attached image") == true)
        XCTAssertTrue(request?.prompt.contains("RECEIPT") == true)
        XCTAssertEqual(stored.source, .gemma)
        XCTAssertEqual(stored.reading.categoryName, "Transfer")
        XCTAssertEqual(stored.reading.expenseDescription, "Transfer")
    }
}
