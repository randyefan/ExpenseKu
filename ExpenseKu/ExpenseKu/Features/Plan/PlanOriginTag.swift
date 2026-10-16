//
//  PlanOriginTag.swift
//  ExpenseKu
//
//  A paid-early tag (envelope-assignment.md §4.10.5) is dashed and points forward: the
//  row is Outside plan in this cycle, so it must not read like an envelope tag, which is
//  From plan. Its "· Nov" never truncates; the name gives way first.
//
//  The tag sits on its own line, so it hugs its text and truncates only at the width of
//  the row's text column (envelope-assignment.md §4.11).
//

import SwiftUI

extension EnvironmentValues {
    @Entry var planOrigins = PlanOrigins(plans: [], payday: 1, calendar: .current)
    /// Off inside an envelope's detail, where every row counts in that envelope and its
    /// tag would only repeat the title (envelope-detail.md §4.4).
    @Entry var showsPlanOriginTags = true
}

struct PlanOriginTag: View {
    let origin: PlanOrigin

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .semibold))
            Text(title)
                .font(.dsCaption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .truncationMode(.tail)
            if case .paidEarly(_, let label) = origin {
                Text("· \(label.short)")
                    .font(.dsCaption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .foregroundStyle(Theme.plan)
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background {
            switch origin {
            case .fixed:
                Capsule().fill(Theme.planWash)
            case .envelope:
                Capsule().strokeBorder(Theme.plan, lineWidth: 1)
            case .paidEarly:
                Capsule().strokeBorder(Theme.plan, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
    }

    private var title: String {
        switch origin {
        case .fixed: "Plan"
        case .envelope(let name): name
        case .paidEarly(let name, _): name
        }
    }

    private var symbol: String {
        switch origin {
        case .fixed: "checklist"
        case .envelope: "tray"
        case .paidEarly: "arrow.forward"
        }
    }

    private var accessibilityTitle: String {
        switch origin {
        case .fixed: "From plan"
        case .envelope(let name): "Envelope \(name)"
        case .paidEarly(let name, let label): "Paid early, \(name), \(label.long)"
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        PlanOriginTag(origin: .fixed)
        PlanOriginTag(origin: .envelope(name: "Hidup"))
    }
    .padding()
    .appBackground()
}
