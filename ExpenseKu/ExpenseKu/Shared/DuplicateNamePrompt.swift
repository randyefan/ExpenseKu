//
//  DuplicateNamePrompt.swift
//  ExpenseKu
//
//  The inline prompt shown when a name already exists (ADR-0002). CloudKit cannot
//  enforce uniqueness, so rather than silently reusing or blindly duplicating, the
//  owner is asked: reuse the existing entity, create a duplicate anyway, or back out.
//
//  It arrives on `.rise` rather than appearing outright — the prompt is an answer
//  to the Save the owner just pressed, and pushing the rest of the form down with
//  no travel reads as a layout glitch rather than a response.
//

import SwiftUI

struct DuplicateNamePrompt: View {
    let existingName: String
    let noun: String
    let onUseExisting: () -> Void
    let onCreateAnyway: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Metric.cardGap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.accentText)
                VStack(alignment: .leading, spacing: 2) {
                    Text("“\(existingName)” already exists")
                        .font(.dsBody).bold()
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("You already have a \(noun) with this name.")
                        .font(.dsSubhead)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .cardStyle()

            Button("Use existing", action: onUseExisting)
                .buttonStyle(FilledPromptButton())

            Button("Create new anyway", action: onCreateAnyway)
                .buttonStyle(OutlinedPromptButton())

            Button("Cancel", action: onCancel)
                .font(.dsBody)
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, 2)
                .buttonStyle(.pressableCard)
        }
    }
}

private struct FilledPromptButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dsBody).fontWeight(.semibold)
            .foregroundStyle(Theme.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: Metric.cardRadius))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .motion(Motion.press, value: configuration.isPressed)
    }
}

private struct OutlinedPromptButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dsBody).fontWeight(.semibold)
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: Metric.cardRadius)
                    .fill(Theme.card)
                    .stroke(Theme.accent.opacity(0.5), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .motion(Motion.press, value: configuration.isPressed)
    }
}

#Preview {
    DuplicateNamePrompt(
        existingName: "Makan",
        noun: "category",
        onUseExisting: {}, onCreateAnyway: {}, onCancel: {}
    )
    .padding()
    .appBackground()
}
