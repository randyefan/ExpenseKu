import SwiftUI

struct SegmentedToggleOptions<Value: Hashable>: View {
    @Binding var selection: Value
    let segments: [SegmentedToggle<Value>.Segment]
    let isCompact: Bool
    var stacksLabels = false

    @Namespace private var pill
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 4) {
            ForEach(segments) { segment in
                let isSelected = segment.value == selection
                Button {
                    withAnimation(reduceMotion ? Motion.reduced : Motion.snap) {
                        selection = segment.value
                    }
                } label: {
                    Group {
                        if stacksLabels {
                            VStack(spacing: 5) {
                                Image(systemName: segment.systemImage)
                                Text(segment.title)
                                    .lineLimit(2, reservesSpace: true)
                            }
                            .frame(maxWidth: .infinity)
                        } else if isCompact {
                            HStack(spacing: 5) {
                                Image(systemName: segment.systemImage)
                                Text(segment.title)
                            }
                        } else {
                            Label(segment.title, systemImage: segment.systemImage)
                        }
                    }
                    .font(.dsSubhead)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? Theme.onAccent : Theme.textSecondary)
                    .lineLimit(stacksLabels ? 2 : 1)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, isCompact ? 10 : 14)
                    .padding(.vertical, 7)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(Theme.accent)
                                .matchedGeometryEffect(id: "selection", in: pill)
                        }
                    }
                    .contentShape(.capsule)
                }
                .buttonStyle(.pressableCard)
                .accessibilityLabel(segment.title)
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
    }
}
