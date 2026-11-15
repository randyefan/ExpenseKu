//
//  PlanGuideSample.swift
//  ExpenseKu
//
//  The guide's November sample (plan-guide.md §5) in one state, held in an in-memory store
//  that belongs to the guide (plan-guide-visual.md §4.2). The lessons draw the app's own
//  Plan views from it, so nothing here may touch the owner's store: every model is
//  inserted into this container alone and dies with it.
//
//  Calendar dates are fixed to November 2026 with payday 1, whatever today is, so the
//  example always reads as the PRD's month.
//

import Foundation
import SwiftData

@MainActor
final class PlanGuideSample {
    static let payday = 1

    let state: PlanGuideSampleState
    let container: ModelContainer
    let calendar: Calendar
    let cycle: PayCycle
    let today: Date
    let november: CyclePlan
    let december: CyclePlan
    let october: CyclePlan
    let kos: PlanItem
    let harian: PlanItem
    let liburan: PlanItem
    let decemberLiburan: PlanItem
    let jago: Account
    let expenses: [Expense]
    let contents: PlanContents

    init(_ state: PlanGuideSampleState) {
        self.state = state
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        self.calendar = calendar
        let novemberDay = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)) ?? .now
        cycle = PayCycle.containing(novemberDay, payday: Self.payday, calendar: calendar)
        today = novemberDay
        let decemberCycle = cycle.next(payday: Self.payday, calendar: calendar)
        let octoberCycle = cycle.previous(payday: Self.payday, calendar: calendar)

        let schema = Schema(versionedSchema: ExpenseKuSchemaV9.self)
        let configuration = ModelConfiguration("PlanGuideSample", schema: schema,
                                               isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            container = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("The guide's in-memory sample store could not open: \(error)")
        }
        let context = container.mainContext

        func insert<Model: PersistentModel>(_ model: Model) -> Model {
            context.insert(model)
            return model
        }
        func day(_ offset: Int, of cycle: PayCycle) -> Date {
            calendar.date(byAdding: .day, value: offset, to: cycle.start) ?? cycle.start
        }

        let housing = insert(CategoryGroup(name: AppLocalization.string(.guideSampleHousing), colorHex: AppearancePalette.swatches[4]))
        let daily = insert(CategoryGroup(name: AppLocalization.string(.guideSampleDaily), colorHex: AppearancePalette.swatches[8]))
        let travel = insert(CategoryGroup(name: AppLocalization.string(.guideSampleTravel), colorHex: AppearancePalette.swatches[2]))
        let sewa = insert(Category(name: AppLocalization.string(.guideSampleHousing), iconName: "house.fill", group: housing))
        let makan = insert(Category(name: "Makan", iconName: "fork.knife", group: daily))
        let transport = insert(Category(name: "Transport", iconName: "car.fill", group: daily))
        let tiket = insert(Category(name: AppLocalization.string(.guideSampleTickets), iconName: "airplane", group: travel))

        jago = insert(Account(name: "Jago"))
        jago.brandID = "jago"
        let mandiri = insert(Account(name: "Mandiri"))
        mandiri.brandID = "mandiri"
        let danamon = insert(Account(name: "CC Danamon"))
        danamon.brandID = "danamon"

        october = insert(CyclePlan(cycleStart: octoberCycle.start))
        _ = insert(PlanItem(name: "Harian", amount: 1_800_000, kind: .envelope, plan: october,
                            account: jago, envelopeCategories: [makan, transport]))

        december = insert(CyclePlan(cycleStart: decemberCycle.start))
        _ = insert(IncomeLine(name: "Gaji", amount: 8_000_000, plan: december))
        decemberLiburan = insert(PlanItem(name: "Liburan", amount: 2_000_000, kind: .envelope, plan: december,
                                          account: jago, envelopeCategories: [tiket]))

        november = insert(CyclePlan(cycleStart: cycle.start))
        _ = insert(IncomeLine(name: "Gaji", amount: 8_000_000, hasArrived: state.gajiArrived, plan: november))
        kos = insert(PlanItem(name: "Kos", amount: 2_200_000, kind: .fixed, dueDay: 5, isAuto: state.kosIsAuto,
                              createdAt: day(0, of: cycle), plan: november, category: sewa,
                              account: state.kosHasAccount ? mandiri : nil))
        harian = insert(PlanItem(name: "Harian", amount: 1_800_000, kind: .envelope,
                                 createdAt: day(0, of: cycle).addingTimeInterval(1), plan: november,
                                 account: jago, envelopeCategories: [makan, transport]))
        liburan = insert(PlanItem(name: "Liburan", kind: .setAside, createdAt: day(0, of: cycle).addingTimeInterval(2),
                                  plan: november, account: jago))
        liburan.amount = 1_000_000
        liburan.setAsideTarget = decemberLiburan
        harian.isFunded = state.harianFunded

        var spending: [Expense] = []
        switch state.kos {
        case .planned:
            break
        case .funded:
            kos.isFunded = true
        case .done, .autoPosted:
            kos.isFunded = true
            spending.append(insert(Expense(amount: 2_200_000, date: day(4, of: cycle), note: "Kos",
                                           category: sewa, account: kos.account, planItem: kos,
                                           needsReview: state.kos == .autoPosted)))
        }

        if state.harianSpent > 0 {
            spending.append(insert(Expense(amount: 45_000, date: day(1, of: cycle), note: "Kopi",
                                           category: makan, account: jago)))
            let grab = insert(Expense(amount: 75_000, date: day(2, of: cycle), note: "Grab",
                                      category: transport, account: danamon))
            grab.isMovedFromEnvelope = state.paidElsewhereMoved
            spending.append(grab)
        }
        if state.harianSpent >= PlanGuideSampleState.harianWithMakan {
            let lunch = insert(Expense(amount: 45_000, date: day(2, of: cycle), note: "Makan siang",
                                       category: makan, account: jago))
            lunch.envelope = harian
            spending.append(lunch)
        }
        let groceries = state.harianSpent - PlanGuideSampleState.harianWithMakan
        if groceries > 0 {
            spending.append(insert(Expense(amount: groceries, date: day(5, of: cycle),
                                           note: AppLocalization.string(.guideSampleGroceries),
                                           category: makan, account: jago)))
        }
        if state.paidEarlyTicket {
            let ticket = insert(Expense(amount: 300_000, date: day(6, of: cycle),
                                        note: AppLocalization.string(.guideSampleFlightTicket),
                                        category: tiket, account: jago))
            ticket.envelope = decemberLiburan
            spending.append(ticket)
        }
        expenses = spending

        try? context.save()
        contents = PlanContents(plan: november, cycle: cycle, cycleExpenses: spending, calendar: calendar)
    }

    var makan: Category? { harian.envelopeCategories?.first { $0.name == "Makan" } }

    var harianExpenses: [Expense] {
        expenses.filter { EnvelopeClaims(envelopes: [harian], cycle: cycle).envelope(for: $0) != nil }
    }
}
