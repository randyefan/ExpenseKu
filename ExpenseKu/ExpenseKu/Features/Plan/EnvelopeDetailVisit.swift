//
//  EnvelopeDetailVisit.swift
//  ExpenseKu
//

import Foundation

/// An envelope's detail the owner stepped out of to open another sheet, and the sheet
/// still to open once the detail has finished closing (envelope-detail.md §4.6).
struct EnvelopeDetailVisit {
    let envelope: PlanItem
    let cycle: PayCycle
    var pending: EnvelopeDetailAction?
}
