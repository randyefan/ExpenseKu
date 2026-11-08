//
//  ReceiptImageData.swift
//  ExpenseKu
//
//  The receipt image an expense keeps until it is checked (ADR-0014), at a size that
//  stays readable when zoomed but small in iCloud: at most 1600 points on its long side,
//  as JPEG. A PDF is kept as its first page.
//

import UIKit

nonisolated enum ReceiptImageData {
    static let longSide: CGFloat = 1600

    static func stored(from data: Data) -> Data {
        let imageData = ReceiptOCR.imageData(from: data)
        guard let image = UIImage(data: imageData) else { return imageData }
        let scale = min(1, longSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.75) ?? imageData
    }
}
