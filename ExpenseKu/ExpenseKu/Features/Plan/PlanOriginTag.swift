//
//  PlanOriginTag.swift
//  ExpenseKu
//
//  A paid-early tag (envelope-assignment.md §4.10.5) is dashed and points forward: the
//  row is Outside plan in this cycle, so it must not read like an envelope tag, which is
//  From plan. Its "· Nov" never truncates; the name gives way first.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var planOrigins = PlanOrigins(plans: [], payday: 1, calendar: .current)
}

struct PlanOriginTag: View {
    let origin: PlanOrigin

    @ScaledMetric(relativeTo: .caption) private var maxWidth: CGFloat = 150

    var body: some View {
        WidthCap(maxWidth: maxWidth) {
            tag
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityTitle)
    }

    private var tag: some View {
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

private struct WidthCap: Layout {
    let maxWidth: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = min(proposal.width ?? maxWidth, maxWidth)
        return subviews.first?.sizeThatFits(ProposedViewSize(width: width, height: proposal.height)) ?? .zero
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        subviews.first?.place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
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
