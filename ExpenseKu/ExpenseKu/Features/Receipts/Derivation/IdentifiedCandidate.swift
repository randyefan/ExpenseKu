//
//  IdentifiedCandidate.swift
//  ExpenseKu
//
//  A value the code found on a receipt, with the id the model picks it by and the span
//  it came from. The model may only answer with one of these (ADR-0014).
//

import Foundation

nonisolated protocol IdentifiedCandidate: Sendable {
    var id: String { get }
    var spanID: String { get }
}
