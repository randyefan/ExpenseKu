import Foundation

nonisolated enum PlanCount {
    case item
    case envelope
    case incomeLine
    case expense
    case category

    func resource(for count: Int) -> LocalizedStringResource {
        switch self {
        case .item: .planItemCount(count)
        case .envelope: .planEnvelopeCount(count)
        case .incomeLine: .planIncomeCount(count)
        case .expense: .planExpenseCount(count)
        case .category: .planCategoryCount(count)
        }
    }
}
