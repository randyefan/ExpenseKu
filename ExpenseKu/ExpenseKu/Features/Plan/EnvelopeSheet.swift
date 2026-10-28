//
//  EnvelopeSheet.swift
//  ExpenseKu
//

import Foundation
import SwiftData

/// The envelope sheets the Expenses tab raises, as one item so they share one
/// presentation modifier: a move (§4.6, §4.8), Move expenses here… (§4.9), or an
/// envelope's detail (envelope-detail.md), or one Account of its PAID ELSEWHERE
/// (paid-elsewhere.md §4.5).
enum EnvelopeSheet: Identifiable {
    case move(EnvelopeMoveRequest)
    case gather(PlanItem, PayCycle)
    case detail(PlanItem, PayCycle)
    case paidElsewhere(PlanItem, PayCycle, Account)

    var id: String {
        switch self {
        case .move(let request): "move-\(request.id)"
        case .gather(let envelope, _): "gather-\(envelope.persistentModelID)"
        case .detail(let envelope, _): "detail-\(envelope.persistentModelID)"
        case .paidElsewhere(let envelope, _, let account):
            "paid-elsewhere-\(envelope.persistentModelID)-\(account.persistentModelID)"
        }
    }
}
