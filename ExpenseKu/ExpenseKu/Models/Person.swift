//
//  Person.swift
//  ExpenseKu
//
//  A reusable companion the owner was *with* when spending — not a beneficiary,
//  no bill-splitting. Many-to-many with Expense; powers the People leaderboard.
//

import Foundation
import SwiftData

@Model
final class Person {
    var name: String = ""

    // The single protected "Me" (the owner). Exactly one Person carries this flag;
    // it is auto-selected on a new expense (but can be unselected), pinned to the
    // top of pickers, can't be renamed/deleted, and is hidden from the People
    // leaderboard (which ranks *companions*, not the owner). Defaulted for CloudKit.
    var isMe: Bool = false

    // Deleting a Person removes them from each expense's `people` — the expenses
    // themselves survive. ADR-0001.
    @Relationship(deleteRule: .nullify, inverse: \Expense.people)
    var expenses: [Expense]? = []

    init(name: String = "", isMe: Bool = false) {
        self.name = name
        self.isMe = isMe
    }
}

extension Person {
    /// The default display name for the protected owner entry.
    static let meName = "Me"

    /// Guarantees exactly one protected "Me" exists — creating it on first run and
    /// healing duplicates thereafter. Called at app launch *and* on every CloudKit
    /// remote change (see RootView), because SwiftData mirrored to CloudKit can't
    /// enforce a unique constraint (ADR-0002): two devices each running the
    /// first-run insert before they sync will produce two `isMe` records.
    ///
    /// When more than one exists, the extras are merged into a single survivor:
    /// every expense tagged with a duplicate is re-tagged onto the survivor, then
    /// the duplicate is deleted (which nullifies its remaining links, ADR-0001).
    /// Idempotent and safe to call often.
    @MainActor
    static func reconcileMe(in context: ModelContext) {
        let descriptor = FetchDescriptor<Person>(predicate: #Predicate { $0.isMe })
        guard let mes = try? context.fetch(descriptor) else { return }

        // First run: no owner yet — create it. Saved right away because the persistent
        // ID is temporary until the first save, and `canonicalMe`'s last tiebreak
        // compares those IDs across devices — an unsaved temp ID makes it unstable.
        guard let survivor = canonicalMe(among: mes) else {
            context.insert(Person(name: meName, isMe: true))
            try? context.save()
            return
        }

        // Unique already — the common case, nothing to heal.
        guard mes.count > 1 else { return }

        // Fold each duplicate's expenses onto the survivor, then delete it.
        for duplicate in mes where duplicate !== survivor {
            for expense in duplicate.expenses ?? [] {
                var people = expense.people ?? []
                if !people.contains(where: { $0 === survivor }) {
                    people.append(survivor)
                }
                people.removeAll { $0 === duplicate }
                expense.people = people
            }
            context.delete(duplicate)
        }

        // The survivor keeps the protected name even if a duplicate had been renamed.
        if survivor.name != meName { survivor.name = meName }

        // Persist immediately: this also runs from the CloudKit remote-change handler, so
        // if the app is killed before autosave fires the merge is lost, never pushed back
        // to CloudKit, and the duplicate "Me" survives on every device.
        try? context.save()
    }

    /// Picks the survivor when duplicate "Me" records exist: most-used first, then by
    /// name, then by identity. Returns nil only when there are no "Me" records at all.
    ///
    /// The first two keys agree across devices. The third does not: persistent IDs are
    /// only stable once saved, and their string form is not a documented ordering — so
    /// this is best-effort, not a convergence guarantee. It only decides between records
    /// that are otherwise identical, where either choice is equally correct locally, and
    /// reconcile re-runs on the next remote change to fold whichever loser arrives.
    /// A real guarantee needs a tiebreak stored in the data itself, which is a schema
    /// change — see the vault note "Temp ID Tiebreak".
    private static func canonicalMe(among mes: [Person]) -> Person? {
        mes.min { a, b in
            let ca = a.expenses?.count ?? 0
            let cb = b.expenses?.count ?? 0
            if ca != cb { return ca > cb }
            if a.name != b.name { return a.name < b.name }
            return "\(a.persistentModelID)" < "\(b.persistentModelID)"
        }
    }
}
