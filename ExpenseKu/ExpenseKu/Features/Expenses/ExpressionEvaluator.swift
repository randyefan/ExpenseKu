//
//  ExpressionEvaluator.swift
//  ExpenseKu
//
//  Backs the calculator keypad in the expense editor. Holds a raw expression
//  string (e.g. "10000÷2") built key-by-key and evaluates it *left-to-right*
//  with no operator precedence — each operator collapses the running result as
//  it's read, so the amount can update live on every keystroke (design: the big
//  amount reflects the current value; the working line shows how we got there).
//
//  Money stays whole-rupiah: division may produce fractions while typing, but
//  `committedAmount` rounds half-up to a whole number for saving.
//

import Foundation

/// The four operators the keypad exposes.
nonisolated enum CalcOperator: Character, CaseIterable {
    case add = "+"
    case subtract = "−"   // U+2212 MINUS SIGN (matches the key glyph)
    case multiply = "×"
    case divide = "÷"

    /// Applies the operator to a running result and the next operand.
    func apply(_ lhs: Decimal, _ rhs: Decimal) -> Decimal {
        switch self {
        case .add:      return lhs + rhs
        case .subtract: return lhs - rhs
        case .multiply: return lhs * rhs
        case .divide:   return rhs == 0 ? lhs : lhs / rhs
        }
    }
}

/// A calculator expression built up from keypad presses. Value semantics so it's
/// trivially testable and cheap to hold in SwiftUI `@State`.
nonisolated struct ExpressionEvaluator: Equatable {
    /// Raw expression, e.g. "10000÷2". Numbers use plain ASCII digits and ".";
    /// operators use the `CalcOperator` glyphs.
    private(set) var raw: String = ""

    init(_ raw: String = "") { self.raw = raw }

    /// Initialises from an existing amount (editing flow) — a bare number, or
    /// empty when the amount is zero so the field reads as "unset".
    init(amount: Decimal) {
        if amount > 0 {
            // Whole-rupiah amounts never carry a fraction, so render plainly.
            self.raw = NSDecimalNumber(decimal: amount).stringValue
        }
    }

    private var operatorGlyphs: Set<Character> { Set(CalcOperator.allCases.map(\.rawValue)) }

    private func isOperator(_ c: Character) -> Bool { operatorGlyphs.contains(c) }

    /// The trailing number token (after the last operator), or "" if the
    /// expression ends in an operator.
    private var currentNumberToken: Substring {
        if let idx = raw.lastIndex(where: { isOperator($0) }) {
            return raw[raw.index(after: idx)...]
        }
        return raw[...]
    }

    // MARK: - Mutation

    /// Appends a digit "0"–"9".
    mutating func appendDigit(_ d: Character) {
        guard d.isNumber else { return }
        // Avoid a leading run of zeros in a token ("007" → "7"), but keep a lone 0.
        let token = currentNumberToken
        if token == "0" {
            raw.removeLast()
        }
        raw.append(d)
    }

    /// Appends a decimal point, guarding against a second point in the same token
    /// and seeding a leading zero ("." → "0.").
    mutating func appendDecimal() {
        let token = currentNumberToken
        if token.contains(".") { return }
        if token.isEmpty { raw.append("0") }
        raw.append(".")
    }

    /// Appends an operator. Ignores a leading operator (empty expression) and
    /// replaces a trailing operator so "10000÷×" becomes "10000×".
    mutating func appendOperator(_ op: CalcOperator) {
        if raw.isEmpty { return }
        if let last = raw.last, isOperator(last) {
            raw.removeLast()
        }
        // Drop a trailing "." so "10.÷2" can't happen.
        if raw.hasSuffix(".") { raw.removeLast() }
        raw.append(op.rawValue)
    }

    /// Deletes the last character.
    mutating func backspace() {
        guard !raw.isEmpty else { return }
        raw.removeLast()
    }

    /// Clears the whole expression.
    mutating func clear() { raw = "" }

    // MARK: - Evaluation

    /// The evaluated value, left-to-right. A trailing operator evaluates to the
    /// left-hand side; an empty expression is zero.
    var value: Decimal {
        var result: Decimal = 0
        var pendingOp: CalcOperator?
        var numberBuffer = ""
        var started = false

        func flush() {
            let operand = Decimal(string: numberBuffer) ?? 0
            if !started {
                result = operand
                started = true
            } else if let op = pendingOp {
                result = op.apply(result, operand)
            }
            numberBuffer = ""
        }

        for c in raw {
            if isOperator(c) {
                if numberBuffer.isEmpty {
                    // Leading/dangling operator — nothing to fold yet.
                    continue
                }
                flush()
                pendingOp = CalcOperator(rawValue: c)
            } else {
                numberBuffer.append(c)
            }
        }
        if !numberBuffer.isEmpty { flush() }
        return result
    }

    /// The value rounded half-up to a whole rupiah, ready to save.
    var committedAmount: Decimal {
        var input = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &input, 0, .plain)
        return rounded
    }

    /// True when the expression contains at least one operator, i.e. there's a
    /// working line worth showing above the result.
    var hasExpression: Bool { raw.contains(where: isOperator) }

    /// The working line with grouped numbers and spaced operators,
    /// e.g. "10,000 ÷ 2". Empty when the expression is a bare number.
    var displayExpression: String {
        guard hasExpression else { return "" }
        var out = ""
        var numberBuffer = ""

        func flushNumber() {
            guard !numberBuffer.isEmpty else { return }
            out += group(numberBuffer)
            numberBuffer = ""
        }

        for c in raw {
            if isOperator(c) {
                flushNumber()
                out += " \(c) "
            } else {
                numberBuffer.append(c)
            }
        }
        flushNumber()
        return out
    }

    /// Groups a raw number token ("1000000" or "1000.5") with thousands
    /// separators, preserving any in-progress decimal part verbatim.
    private func group(_ token: String) -> String {
        let parts = token.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let intPart = String(parts.first ?? "")
        let grouped = (Decimal(string: intPart) ?? 0)
            .formatted(.number.precision(.fractionLength(0)))
        if token.contains(".") {
            let frac = parts.count > 1 ? String(parts[1]) : ""
            return "\(grouped).\(frac)"
        }
        return grouped
    }
}
