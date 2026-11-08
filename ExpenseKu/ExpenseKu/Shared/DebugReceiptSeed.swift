//
//  DebugReceiptSeed.swift
//  ExpenseKu
//
//  DEBUG-only: -seedReceipts puts flow AG's sample on the simulator (receipt-reading.md
//  §8). A BCA Account wearing its logo, a Lovely Support Category, two synthetic receipts
//  in the inbox (the BCA transfer and an Indomaret shop receipt, drawn with SwiftUI so OCR
//  has real pixels to read), and one Belanja expense from a receipt still to check.
//

#if DEBUG
import SwiftData
import SwiftUI

enum DebugReceiptSeed {
    static var isRequested: Bool { ProcessInfo.processInfo.arguments.contains("-seedReceipts") }

    @MainActor
    static func seedIfNeeded(_ context: ModelContext, inbox: ReceiptInbox) {
        guard isRequested else { return }
        let accounts = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        if !accounts.contains(where: { $0.brandID == "bca" }) {
            let bca = Account(name: "BCA")
            bca.brandID = "bca"
            context.insert(bca)
        }
        let categories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        if !categories.contains(where: { $0.name == "Lovely Support" }) {
            context.insert(Category(name: "Lovely Support", iconName: "heart.fill"))
        }
        let belanja = categories.first { $0.name == "Belanja" } ?? {
            let category = Category(name: "Belanja", iconName: "bag.fill")
            context.insert(category)
            return category
        }()

        if inbox.items.isEmpty {
            if let bca = render(DebugReceiptImage.bca) { inbox.add(bca, fileExtension: "png") }
            if let shop = render(DebugReceiptImage.indomaret) { inbox.add(shop, fileExtension: "png") }
        }

        let flagged = (try? context.fetch(FetchDescriptor<Expense>(predicate: #Predicate { $0.needsReview }))) ?? []
        if !flagged.contains(where: \.isReceiptToCheck), let shop = render(DebugReceiptImage.indomaret) {
            let date = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
            let expense = Expense(amount: 28_600, date: date, note: "INDOMARET", category: belanja, needsReview: true)
            expense.receiptImage = ReceiptImageData.stored(from: shop)
            context.insert(expense)
        }
        try? context.save()
    }

    @MainActor
    private static func render(_ lines: [DebugReceiptLine]) -> Data? {
        let renderer = ImageRenderer(content: DebugReceiptImage(lines: lines))
        renderer.scale = 2
        return renderer.uiImage?.pngData()
    }
}

struct DebugReceiptLine: Hashable {
    let left: String
    var right: String = ""
    var big = false
}

struct DebugReceiptImage: View {
    let lines: [DebugReceiptLine]

    static let bca: [DebugReceiptLine] = [
        .init(left: "BCA", right: "m-Transfer", big: true),
        .init(left: "Transfer Berhasil"),
        .init(left: "22 Agu 2026 14:28:05"),
        .init(left: "Tujuan", right: "MUHAMMAD FADHIL"),
        .init(left: "Nominal", right: "Rp 60.000,00"),
        .init(left: "Biaya", right: "Rp 2.500,00"),
        .init(left: "Transfer 200x dapat cashback"),
    ]

    static let indomaret: [DebugReceiptLine] = [
        .init(left: "INDOMARET", big: true),
        .init(left: "Jl. Kaliurang Km 5"),
        .init(left: "07/11/2026 14:32"),
        .init(left: "AQUA 600ML 2 x 3.500", right: "7.000"),
        .init(left: "ROTI TAWAR", right: "21.600"),
        .init(left: "TOTAL", right: "28.600"),
        .init(left: "TUNAI", right: "50.000"),
        .init(left: "KEMBALI", right: "21.400"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(lines, id: \.self) { line in
                HStack {
                    Text(line.left)
                    Spacer(minLength: 24)
                    Text(line.right)
                }
                .font(.system(size: line.big ? 30 : 22, weight: line.big ? .bold : .regular, design: .monospaced))
            }
        }
        .foregroundStyle(.black)
        .padding(32)
        .frame(width: 600)
        .background(.white)
    }
}
#endif
