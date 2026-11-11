//
//  ReceiptModelCard.swift
//  ExpenseKu
//
//  The MODEL card on Receipt reading, one shape per phase: Download, progress with
//  Pause, Resume with the error, or Remove (docs/prd/receipt-reading.md §4.10, AG9). A
//  paused download can be removed too, so a half-finished one never strands its space.
//

import SwiftUI

struct ReceiptModelCard: View {
    let phase: ReceiptModelPhase
    let onDownload: () -> Void
    let onPause: () -> Void
    let onRemove: () -> Void

    private var status: String {
        switch phase {
        case .notDownloaded: AppLocalization.string(.receiptModelNotDownloaded)
        case .downloading: AppLocalization.string(.receiptModelDownloading)
        case .paused(_, _, let error): error ?? AppLocalization.string(.paused)
        case .ready: AppLocalization.string(.receiptModelOnDevice)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                if phase == .ready {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.positive)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gemma 4 E2B")
                        .font(.dsBody).fontWeight(.semibold)
                        .foregroundStyle(Theme.text)
                    Text(status)
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(3)
                }
                Spacer(minLength: 8)
                if case .downloading = phase {
                    Button(AppLocalization.string(.pause), systemImage: "pause.fill", action: onPause)
                        .font(.dsSubhead.weight(.semibold))
                        .foregroundStyle(Theme.text)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 36)
                        .background(Theme.surface, in: .capsule)
                }
            }

            switch phase {
            case .downloading, .paused:
                ProgressView(value: phase.fraction)
                    .tint(Theme.accent)
                HStack {
                    Text(phase.fraction, format: .percent.precision(.fractionLength(0)))
                        .font(.dsCaption).fontWeight(.semibold)
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Text(progressBytes)
                        .font(.dsCaption)
                        .monospacedDigit()
                        .foregroundStyle(Theme.textSecondary)
                }
            default:
                EmptyView()
            }

            switch phase {
            case .notDownloaded:
                wideButton(AppLocalization.string(.downloadModel), systemImage: "arrow.down.circle", prominent: true, action: onDownload)
            case .paused:
                wideButton(AppLocalization.string(.resume), systemImage: "arrow.clockwise", prominent: true, action: onDownload)
                Button(AppLocalization.string(.removeDownload), role: .destructive, action: onRemove)
                    .font(.dsSubhead.weight(.semibold))
                    .foregroundStyle(Theme.negative)
                    .frame(maxWidth: .infinity)
            case .ready:
                Button(action: onRemove) {
                    Text(appLocalized: .removeModel)
                        .font(.dsSubhead).fontWeight(.semibold)
                        .foregroundStyle(Theme.negative)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Theme.surface, in: .capsule)
                }
                .buttonStyle(.pressableCard)
            case .downloading:
                EmptyView()
            }
        }
        .padding(Metric.cardPadding)
        .background {
            RoundedRectangle(cornerRadius: Metric.cardRadius)
                .fill(Theme.card)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        }
    }

    private var progressBytes: String {
        switch phase {
        case .downloading(let received, let total), .paused(let received, let total, _):
            AppLocalization.string(.modelBytesProgress(ReceiptModelPhase.gigabytes(received), String(ReceiptModelPhase.gigabytes(total))))
        default: ""
        }
    }

    private func wideButton(_ title: String, systemImage: String, prominent: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.dsSubhead).fontWeight(.semibold)
                .foregroundStyle(Theme.onAccent)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Theme.accent, in: .capsule)
        }
        .buttonStyle(.pressableCard)
    }
}
