//
//  LogoTrim.swift
//  ExpenseKu
//
//  The opaque part of a bank logo (docs/prd/bank-logos.md §5.5). Catalog images are
//  square with the wordmark centred in transparent bands, so a wide chip drawing the
//  whole square would shrink the letters to the height of the band. Trimming to the
//  pixels that carry ink lets the chip fill with the wordmark itself.
//
//  Near-transparent pixels count as empty: antialiased edges and export noise would
//  otherwise hold the bounds open.
//

import CoreGraphics

nonisolated enum LogoTrim {
    static let threshold: UInt8 = 8

    /// The smallest rectangle, in pixels, holding every pixel whose alpha exceeds
    /// `threshold`. `alpha` is row-major, `width × height` bytes. Nil when nothing does.
    static func opaqueBounds(alpha: [UInt8], width: Int, height: Int, threshold: UInt8 = threshold) -> CGRect? {
        guard width > 0, height > 0, alpha.count >= width * height else { return nil }
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            let row = y * width
            for x in 0..<width where alpha[row + x] > threshold {
                minX = min(minX, x)
                maxX = max(maxX, x)
                minY = min(minY, y)
                maxY = max(maxY, y)
            }
        }
        guard maxX >= 0 else { return nil }
        return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }
}
