//
//  ReceiptThumbnail.swift
//  ExpenseKu
//
//  A receipt image at a fixed size, cropped to its top, which is where a receipt says
//  who and how much.
//

import SwiftUI

struct ReceiptThumbnail: View {
    let data: Data?
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Group {
            if let data, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height, alignment: .top)
            } else {
                Theme.surface
                    .overlay {
                        Image(systemName: "receipt")
                            .foregroundStyle(Theme.textSecondary)
                    }
            }
        }
        .frame(width: width, height: height)
        .clipShape(.rect(cornerRadius: 10))
    }
}
