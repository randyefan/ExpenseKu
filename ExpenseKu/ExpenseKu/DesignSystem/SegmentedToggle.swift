//
//  SegmentedToggle.swift
//  ExpenseKu — DesignSystem
//
//  A small two-or-more segment switch in the Warm Cards language: a muted capsule
//  track with the active segment filled coral (the reserved "selected state" use).
//  A stock .pickerStyle(.segmented) cannot take the coral fill cleanly, hence this.
//

import SwiftUI

/// A small two-or-more segment switch in the Warm Cards language: a muted capsule
/// track with the active segment filled coral (the reserved "selected state" use).
/// A stock `.pickerStyle(.segmented)` can't take the coral fill cleanly, hence this.
struct SegmentedToggle<Value: Hashable>: View {
    struct Segment: Identifiable {
        let value: Value
        let title: String
        let systemImage: String
        var id: Value { value }

        init(_ value: Value, title: String, systemImage: String) {
            self.value = value
            self.title = title
            self.systemImage = systemImage
        }
    }

    @Binding var selection: Value
    let segments: [Segment]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(segments) { segment in
                let isSelected = segment.value == selection
                Button {
                    selection = segment.value
                } label: {
                    Label(segment.title, systemImage: segment.systemImage)
                        .font(.dsSubhead)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? Color.white : Theme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background {
                            if isSelected {
                                Capsule().fill(Theme.accent)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(segment.title)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(3)
        .background(Theme.textSecondary.opacity(0.1), in: Capsule())
    }
}

private enum PreviewLens: Hashable { case list, calendar }

#Preview {
    @Previewable @State var lens = PreviewLens.list
    SegmentedToggle(
        selection: $lens,
        segments: [
            .init(.list, title: "List", systemImage: "list.bullet"),
            .init(.calendar, title: "Month", systemImage: "calendar"),
        ]
    )
    .padding()
    .warmBackground()
}
