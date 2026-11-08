//
//  ReceiptOCRThumbnail.swift
//  ExpenseKuShare
//
//  The shared file as an image for the share sheet's thumbnail: a PDF shows its first page.
//

import PDFKit
import UIKit

enum ReceiptOCRThumbnail {
    static func imageData(_ payload: SharedReceipt.Payload) -> Data {
        guard payload.fileExtension == "pdf", let page = PDFDocument(data: payload.data)?.page(at: 0) else {
            return payload.data
        }
        return page.thumbnail(of: CGSize(width: 280, height: 400), for: .mediaBox).pngData() ?? payload.data
    }
}
