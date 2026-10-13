//
//  EnvelopeField.swift
//  ExpenseKu
//

import SwiftUI

/// What the expense editor hands its Envelope row: the draft's choice, how it reads,
/// and the plan and cycle the picker offers envelopes from.
struct EnvelopeField {
    let choice: Binding<EnvelopeChoice>
    let value: EnvelopeRowValue
    let plan: CyclePlan?
    let cycle: PayCycle
}
