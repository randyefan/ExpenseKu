//
//  DuplicateNamePrompt.swift
//  ExpenseKu
//
//  The inline prompt shown when a name already exists (ADR-0002). CloudKit cannot
//  enforce uniqueness, so rather than silently reusing or blindly duplicating, the
//  owner is asked: reuse the existing entity, create a duplicate anyway, or back out.
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
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("“\(existingName)” already exists")
                        .font(.dsBody).bold()
                        .foregroundStyle(Theme.text)
                    Text("You already have a \(noun) with this name.")
                        .font(.dsSubhead)
                        .foregroundStyle(Theme.textSecondary)
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
        }
    }
}

private struct FilledPromptButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.dsBody).fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: Metric.cardRadius))
            .opacity(configuration.isPressed ? 0.85 : 1)
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
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

#Preview {
    DuplicateNamePrompt(
        existingName: "Makan",
        noun: "category",
        onUseExisting: {}, onCreateAnyway: {}, onCancel: {}
    )
    .padding()
    .warmBackground()
}
