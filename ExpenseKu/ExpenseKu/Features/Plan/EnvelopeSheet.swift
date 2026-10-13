//
//  EnvelopeSheet.swift
//  ExpenseKu
//

import Foundation
import SwiftData

/// The envelope sheets the Expenses tab raises, as one item so they share one
/// presentation modifier: a move (§4.6, §4.8) or Move expenses here… (§4.9).
enum EnvelopeSheet: Identifiable {
    case move(EnvelopeMoveRequest)
    case gather(PlanItem, PayCycle)

    var id: String {
        switch self {
        case .move(let request): "move-\(request.id)"
        case .gather(let envelope, _): "gather-\(envelope.persistentModelID)"
        }
    }
}
