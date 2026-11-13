import Foundation
@testable import ExpenseKu

actor ReceiptImageModelProbe: ReceiptModel {
    private(set) var request: (prompt: String, image: Data)?

    func answer(_ prompt: String, image: Data) async throws -> String {
        request = (prompt, image)
        return #"{"category": "Transfer", "description": "Transfer"}"#
    }
}
