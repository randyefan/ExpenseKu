//
//  TourChapter.swift
//  ExpenseKu
//

import Foundation

nonisolated enum TourChapter: Int, CaseIterable, Codable, Comparable, Hashable, Sendable {
    case record = 1
    case browse
    case plan
    case insights

    static func < (lhs: TourChapter, rhs: TourChapter) -> Bool { lhs.rawValue < rhs.rawValue }

    var next: TourChapter? { TourChapter(rawValue: rawValue + 1) }

    var title: LocalizedStringResource {
        switch self {
        case .record: .tourChapterRecord
        case .browse: .tourChapterBrowse
        case .plan: .tourChapterPlan
        case .insights: .tourChapterInsights
        }
    }

    var detail: LocalizedStringResource {
        switch self {
        case .record: .tourChapterRecordDetail
        case .browse: .tourChapterBrowseDetail
        case .plan: .tourChapterPlanDetail
        case .insights: .tourChapterInsightsDetail
        }
    }

    var recap: LocalizedStringResource {
        switch self {
        case .record: .tourChapterRecordRecap
        case .browse: .tourChapterBrowseRecap
        case .plan: .tourChapterPlanRecap
        case .insights: .tourChapterInsightsRecap
        }
    }
}
