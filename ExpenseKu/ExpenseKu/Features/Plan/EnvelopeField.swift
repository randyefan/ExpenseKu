//
//  EnvelopeField.swift
//  ExpenseKu
//

import SwiftUI

/// What the expense editor hands its Envelope row: the draft's choice, how it reads,
/// and the envelopes the picker offers.
struct EnvelopeField {
    let choice: Binding<EnvelopeChoice>
    let value: EnvelopeRowValue
    let offer: EnvelopeOffer
}
