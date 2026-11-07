//
//  WhenShortcutRow.swift
//  ExpenseKu
//
//  WHEN in the expense editor (docs/prd/quick-entry-form.md §4.1): the resolved date and
//  time in the system's compact picker, over a rail of Now · 1h ago · 3h ago ·
//  Yesterday and a calendar chip for any other moment.
//

import SwiftUI

struct WhenShortcutRow: View {
    @Binding var date: Date
    @Binding var tap: WhenTap?
    @State private var showsCalendar = false

    private var selection: WhenSelection {
        WhenSelection.resolve(date: date, tap: tap, now: .now, calendar: .current)
    }

    var body: some View {
        QuickEntrySection(title: "When") {
            DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
        } content: {
            ChipRail(fade: Metric.screenPadding) {
                if case .custom(let custom) = selection {
                    QuickChip(title: Self.customTitle(custom), isSelected: true) {
                        showsCalendar = true
                    }
                }
                ForEach(WhenShortcut.allCases, id: \.self) { shortcut in
                    QuickChip(title: shortcut.title, isSelected: selection == .shortcut(shortcut)) {
                        choose(shortcut)
                    }
                }
                Button {
                    showsCalendar = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.dsSubhead).fontWeight(.semibold)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(minWidth: 36, minHeight: 36)
                        .padding(.horizontal, 4)
                        .background {
                            Capsule().fill(Theme.card).strokeBorder(Theme.hairline, lineWidth: 1)
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.pressableCard)
                .accessibilityLabel("Pick a date")
            }
            // Anchored to the rail, not the calendar chip: picking a date adds a chip ahead
            // of the shortcuts, which slid a chip-anchored popover off the screen.
            .popover(isPresented: $showsCalendar, arrowEdge: .top) {
                DatePicker("Date & Time", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                    .frame(minWidth: 320)
                    .presentationCompactAdaptation(.popover)
            }
        }
    }

    static func customTitle(_ date: Date) -> String {
        let day = date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        return "\(day), \(date.formatted(date: .omitted, time: .shortened))"
    }

    private func choose(_ shortcut: WhenShortcut) {
        let chosen = shortcut.date(from: .now, calendar: .current)
        date = chosen
        tap = WhenTap(shortcut: shortcut, date: chosen)
    }
}
