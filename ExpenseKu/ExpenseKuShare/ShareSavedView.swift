//
//  ShareSavedView.swift
//  ExpenseKuShare
//
//  What the share sheet shows (docs/prd/receipt-reading.md §4.1, frame AG1): the receipt,
//  "Saved to ExpenseKu", and Done. It reads nothing; the app reads the receipt when the
//  owner opens it.
//

import SwiftUI

struct ShareSavedView: View {
    enum State {
        case saving
        case saved(UIImage?)
        case failed
    }

    let state: State
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .fill(Theme.hairline)
                .frame(width: 36, height: 5)
            HStack(spacing: 14) {
                thumbnail
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: symbol)
                            .foregroundStyle(symbolColor)
                            .accessibilityHidden(true)
                        Text(title)
                            .foregroundStyle(Theme.text)
                    }
                    .font(.headline)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.card)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            }
            Button(action: onDone) {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(Theme.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Theme.accent, in: .capsule)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(Theme.bg, in: .rect(topLeadingRadius: 34, topTrailingRadius: 34))
        .preferredColorScheme(.dark)
    }

    private var title: String {
        switch state {
        case .saving: "Saving…"
        case .saved: "Saved to ExpenseKu"
        case .failed: "Couldn't save this"
        }
    }

    private var detail: String {
        switch state {
        case .saving: "One moment."
        case .saved: "Open ExpenseKu to log it."
        case .failed: "Share an image or a PDF of the receipt."
        }
    }

    private var symbol: String {
        switch state {
        case .saving: "hourglass"
        case .saved: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    private var symbolColor: Color {
        switch state {
        case .saving: Theme.textSecondary
        case .saved: Theme.positive
        case .failed: Theme.negative
        }
    }

    @ViewBuilder private var thumbnail: some View {
        if case .saved(let image?) = state {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 80, alignment: .topLeading)
                .clipShape(.rect(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.surface)
                .frame(width: 56, height: 80)
        }
    }
}
