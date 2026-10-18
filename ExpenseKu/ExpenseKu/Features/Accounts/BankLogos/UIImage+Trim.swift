//
//  UIImage+Trim.swift
//  ExpenseKu
//
//  Crops a bank logo to its opaque bounds (LogoTrim) for the expense row's wordmark
//  chip. An image that cannot be read, or has no opaque pixel, comes back unchanged.
//

import UIKit

extension UIImage {
    func trimmedToOpaque() -> UIImage {
        guard let cgImage else { return self }
        let width = cgImage.width, height = cgImage.height
        var alpha = [UInt8](repeating: 0, count: width * height)
        let drawn = alpha.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width, space: CGColorSpaceCreateDeviceGray(),
                                          bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn,
              let bounds = LogoTrim.opaqueBounds(alpha: alpha, width: width, height: height),
              let cropped = cgImage.cropping(to: bounds) else { return self }
        return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
    }
}
