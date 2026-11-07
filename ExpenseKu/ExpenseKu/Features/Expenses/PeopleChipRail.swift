//
//  PeopleChipRail.swift
//  ExpenseKu
//
//  PEOPLE in the expense editor (docs/prd/quick-entry-form.md §4.4): Me and the most
//  tagged as avatar chips, then All…, a menu that stays open while ticking so several
//  people can be tagged in one visit.
//

import SwiftUI
import SwiftData

struct PeopleChipRail: View {
    let rail: [Person]
    let everyone: [Person]
    @Binding var selection: [Person]
    let onEditPeople: () -> Void

    var body: some View {
        QuickEntrySection(title: "People") {
            ChipRail(fade: Metric.screenPadding) {
                ForEach(rail) { person in
                    QuickChip(title: person.name, isSelected: isSelected(person)) {
                        toggle(person)
                    } lead: {
                        PersonAvatar(person: person, size: 28)
                            .accessibilityHidden(true)
                    }
                }
                Menu {
                    ForEach(everyone) { person in
                        Toggle(person.name, isOn: Binding(
                            get: { isSelected(person) },
                            set: { _ in toggle(person) }
                        ))
                        .menuActionDismissBehavior(.disabled)
                    }
                    Divider()
                    Button("Edit People…", systemImage: "person.2", action: onEditPeople)
                } label: {
                    QuickChipLabel(title: "All…", isSelected: false, isMuted: true)
                }
                .accessibilityLabel("All people")
            }
        }
    }

    private func isSelected(_ person: Person) -> Bool {
        selection.contains { $0.persistentModelID == person.persistentModelID }
    }

    private func toggle(_ person: Person) {
        if let index = selection.firstIndex(where: { $0.persistentModelID == person.persistentModelID }) {
            selection.remove(at: index)
        } else {
            selection.append(person)
        }
    }
}
