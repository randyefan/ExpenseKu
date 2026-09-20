//
//  PlanItem.swift
//  ExpenseKu
//
//  One line of a cycle plan: money the owner *intends* to spend. Not an Expense —
//  that distinction is the whole point of ADR-0005, and every analytics read path in
//  the app depends on it holding.
//
//  Two kinds (PRD §5.1), visible in the spreadsheet's own numbers. Round,
//  forward-looking amounts are Fixed and stand for one transaction: completing one
//  creates a linked Expense. Precise amounts filled in afterwards are Envelopes, an
//  allowance across many small purchases: an Envelope never creates an Expense, and
//  its spent figure is derived from expenses the owner already logged.
//
//  `isDone` is derived from the link rather than stored. PRD §9.5 requires that
//  deleting an Expense returns its item to not-done; with a stored flag that needs a
//  listener and drifts the first time CloudKit merges a delete from another device.
//

import Foundation
import SwiftData

/// What a PlanItem stands for. Stored as its raw String (see `PlanItem.kindRaw`):
/// CloudKit needs a defaulted property, and a raw value leaves room for a third kind
/// without a migration.
enum PlanItemKind: String, Codable, CaseIterable, Sendable {
    case fixed
    case envelope
}

@Model
final class PlanItem {
    var name: String = ""
    /// What the owner *planned*. The actual figure lives on the linked Expense, and
    /// keeping both is what makes plan-vs-actual expressible at all (ADR-0005).
    var amount: Decimal = 0
    var kindRaw: String = PlanItemKind.fixed.rawValue

    /// A day-of-month, not a date, so carry-over reproduces it without re-entry.
    /// Days 29–31 clamp to the end of short months — resolve it through `DueDay`,
    /// never by hand.
    var dueDay: Int?
    /// The money leaves by itself (autodebit, a subscription). With a due day this
    /// item materialises its own Expense (ADR-0007); without one it never fires.
    var isAuto: Bool = false

    /// The `cycleStart` of the last plan in which this item was actually in use.
    /// Carried forward so a dormant row can say when it was last used.
    var lastUsedCycleStart: Date?
    /// This row arrived by carry-over rather than being typed. Dormancy only ever
    /// applies to a copied row, so a Rp 0 item the owner is midway through adding
    /// does not fold itself away as they type.
    var carriedOver: Bool = false
    /// Insertion order. The stable tiebreak under the amount-descending sort, and the
    /// reason two devices render the same plan in the same order.
    var createdAt: Date = Date.now

    var plan: CyclePlan?

    // Fixed only. An Envelope names a set of Categories instead (below) and has no
    // Account at all, because it never produces a transaction to pay from.
    var category: Category?
    var account: Account?
    /// Passed to the Expense this item creates. Person covers recipients as well as
    /// companions since ADR-0006 — "Kirim buat Ibu" is a Person, not a Category.
    var people: [Person]? = []

    /// Envelope only: what this envelope totals. The inverse lives on Category,
    /// following the convention that inverses sit on the tag entity.
    var envelopeCategories: [Category]? = []

    /// The Expense this item created, as a to-many although the domain allows at most
    /// one. ADR-0007 runs materialisation on every device against a store that cannot
    /// enforce uniqueness; a to-one would let last-writer-wins silently orphan the
    /// loser, where a to-many leaves the duplicate visible for `PlanMaterialiser` to
    /// fold — the same shape as `Person.reconcileMe`.
    @Relationship(deleteRule: .nullify, inverse: \Expense.planItem)
    var linkedExpenses: [Expense]? = []

    init(
        name: String = "",
        amount: Decimal = 0,
        kind: PlanItemKind = .fixed,
        dueDay: Int? = nil,
        isAuto: Bool = false,
        lastUsedCycleStart: Date? = nil,
        carriedOver: Bool = false,
        createdAt: Date = .now,
        plan: CyclePlan? = nil,
        category: Category? = nil,
        account: Account? = nil,
        people: [Person] = [],
        envelopeCategories: [Category] = []
    ) {
        self.name = name
        self.amount = amount
        self.kindRaw = kind.rawValue
        self.dueDay = dueDay
        self.isAuto = isAuto
        self.lastUsedCycleStart = lastUsedCycleStart
        self.carriedOver = carriedOver
        self.createdAt = createdAt
        self.plan = plan
        self.category = category
        self.account = account
        self.people = people
        self.envelopeCategories = envelopeCategories
    }
}

extension PlanItem {
    var kind: PlanItemKind {
        get { PlanItemKind(rawValue: kindRaw) ?? .fixed }
        set { kindRaw = newValue.rawValue }
    }

    var isEnvelope: Bool { kind == .envelope }

    /// The one Expense this item stands behind, picking a survivor when sync has left
    /// more than one. Earliest first so the figure the owner saw first wins; the
    /// persistent-ID tiebreak only separates records that are otherwise identical and
    /// is best-effort, exactly as in `Person.canonicalMe(among:)`.
    var linkedExpense: Expense? {
        (linkedExpenses ?? []).min { a, b in
            if a.date != b.date { return a.date < b.date }
            return "\(a.persistentModelID)" < "\(b.persistentModelID)"
        }
    }

    /// Money has actually moved. Derived, never stored — see the file header.
    var isDone: Bool { linkedExpense != nil }

    /// An Auto item only fires once a due day is set, so the switch stays inert
    /// without one (PRD §7.4, frame I8).
    var autoCanFire: Bool { isAuto && dueDay != nil && kind == .fixed }

    /// Carried over but not in use this cycle: no money against it and never
    /// completed. Folded into the "From last cycle" section (PRD §7.2).
    var isDormant: Bool { amount == 0 && !isDone }
}
