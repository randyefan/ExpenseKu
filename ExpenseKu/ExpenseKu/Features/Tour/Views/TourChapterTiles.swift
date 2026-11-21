//
//  TourChapterTiles.swift
//  ExpenseKu
//
//  The four numbered chapter tiles of the opening, ticked on the closing (AO1, AO19).
//

import SwiftUI

struct TourChapterTiles: View {
    var ticked = false

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(TourChapter.allCases, id: \.self) { chapter in
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(ticked ? Theme.accent : Theme.surface)
                        if ticked {
                            Image(systemName: "checkmark")
                                .font(.dsCaption).bold()
                                .foregroundStyle(Theme.onAccent)
                        } else {
                            Text(chapter.rawValue, format: .number)
                                .font(.dsSubhead).bold()
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    .frame(width: 30, height: 30)
                    .accessibilityHidden(true)
                    Text(appLocalized: chapter.title)
                        .font(.dsSubhead).bold()
                        .foregroundStyle(Theme.text)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(Theme.card, in: .rect(cornerRadius: Metric.rowRadius))
                .accessibilityElement(children: .combine)
            }
        }
    }
}
