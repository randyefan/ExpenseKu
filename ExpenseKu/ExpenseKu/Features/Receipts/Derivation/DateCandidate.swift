//
//  DateCandidate.swift
//  ExpenseKu
//

import Foundation

nonisolated struct DateCandidate: IdentifiedCandidate, Hashable {
    let id: String
    let value: LocalDateTime
    let spanID: String
}
