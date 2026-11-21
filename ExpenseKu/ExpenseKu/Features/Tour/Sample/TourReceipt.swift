//
//  TourReceipt.swift
//  ExpenseKu
//
//  The receipt the tour reads in mission 1.7 (welcome-tour.md §4.5). Drawn here and rendered
//  once, so the app carries no image file and the reading needs no model.
//

import SwiftUI

enum TourReceipt {
    static let amount: Decimal = 32_000
    static let note = "Kopi susu"

    @MainActor
    static func imageData() -> Data? {
        let renderer = ImageRenderer(content: TourReceiptPaper())
        renderer.scale = 2
        return renderer.uiImage?.jpegData(compressionQuality: 0.8)
    }
}

struct TourReceiptPaper: View {
    var body: some View {
        VStack(spacing: 10) {
            Text(verbatim: "KOPI SUSU SENJA")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
            Text(verbatim: "Jl. Senja No. 12")
                .font(.system(size: 11, design: .monospaced))
            Divider().overlay(Color.black.opacity(0.4))
            line("Kopi susu", "28.000")
            line("Extra shot", "4.000")
            Divider().overlay(Color.black.opacity(0.4))
            line("TOTAL", "32.000")
                .bold()
            Text(verbatim: "Terima kasih")
                .font(.system(size: 11, design: .monospaced))
                .padding(.top, 6)
        }
        .foregroundStyle(Color.black)
        .padding(20)
        .frame(width: 240)
        .background(Color(red: 0.98, green: 0.97, blue: 0.94))
    }

    private func line(_ item: String, _ amount: String) -> some View {
        HStack {
            Text(verbatim: item)
            Spacer()
            Text(verbatim: amount)
        }
        .font(.system(size: 13, design: .monospaced))
    }
}
