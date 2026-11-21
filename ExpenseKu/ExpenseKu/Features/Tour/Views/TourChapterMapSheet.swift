//
//  TourChapterMapSheet.swift
//  ExpenseKu
//
//  Pick a chapter to play again (welcome-tour.md §4.9, AO22). A chapter plays on to the
//  end of the tour (decision 26).
//

import SwiftUI

struct TourChapterMapSheet: View {
    let done: Set<TourChapter>
    let onPick: (TourEntry) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    WalletMascot(pose: .waving, size: 96)
                    Text(appLocalized: .tourChaptersDone(done.count))
                        .font(.dsHeadline).bold()
                        .foregroundStyle(Theme.text)
                    Text(appLocalized: .tourMapLead)
                        .font(.dsSubhead)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                    VStack(spacing: 0) {
                        ForEach(TourChapter.allCases, id: \.self) { chapter in
                            Button { pick(.chapter(chapter)) } label: {
                                TourChapterMapRow(chapter: chapter, isDone: done.contains(chapter))
                            }
                            .buttonStyle(.pressableRow)
                            if chapter != TourChapter.allCases.last {
                                Divider().overlay(Theme.hairline)
                            }
                        }
                    }
                    .cardStyle()
                    Text(appLocalized: .tourMapFoot)
                        .font(.dsCaption)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                    Button(AppLocalization.string(.tourStartFromBeginning)) { pick(.opening) }
                        .buttonStyle(.tour(.outlined))
                }
                .padding(Metric.screenPadding)
                .readableColumn()
            }
            .background(Theme.bg)
            .navigationTitle(AppLocalization.string(.tourName))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.string(.close)) { dismiss() }
                }
            }
        }
    }

    private func pick(_ entry: TourEntry) {
        onPick(entry)
        dismiss()
    }
}

private struct TourChapterMapRow: View {
    let chapter: TourChapter
    let isDone: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(isDone ? Theme.accent : Theme.surface)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.dsCaption).bold()
                        .foregroundStyle(Theme.onAccent)
                } else {
                    Text(chapter.rawValue, format: .number)
                        .font(.dsSubhead).bold()
                        .foregroundStyle(Theme.accent)
                }
            }
            .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(appLocalized: chapter.title)
                    .font(.dsBody).bold()
                    .foregroundStyle(Theme.text)
                Text(appLocalized: chapter.detail)
                    .font(.dsCaption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.dsSubhead).bold()
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 12)
        .contentShape(.rect)
    }
}
