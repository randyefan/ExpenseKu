//
//  TourLine.swift
//  ExpenseKu
//

import Foundation

nonisolated enum TourLine: Equatable, Sendable {
    case recordAdd, recordAddNudge
    case recordKeypad, recordKeypadNudge
    case recordCategory, recordCategoryNudge
    case recordPerson, recordPersonNudge
    case recordAccount, recordAccountNudge
    case recordSave, recordSaveNudge, recordSaved
    case recordReceipt, recordReceiptNudge, recordReceiptReading, recordReceiptCheck, recordReceiptSaved
    case browsePrevious, browsePreviousNudge
    case browseLastCycle(String), browseNextNudge
    case browseMonth, browseMonthNudge
    case browseSearch, browseSearchNudge, browseSearchType, browseSearchTypeNudge
    case planLens, planLensNudge
    case planIncome, planHarian, planRemaining, spotlightNudge
    case insightsTab, insightsTabNudge
    case insightsMakan, insightsMakanNudge, insightsMakanFound
    case insightsLeaderboard, insightsLeaderboardNudge, insightsIbuFirst

    var resource: LocalizedStringResource {
        switch self {
        case .recordAdd: .tourRecordAdd
        case .recordAddNudge: .tourRecordAddNudge
        case .recordKeypad: .tourRecordKeypad
        case .recordKeypadNudge: .tourRecordKeypadNudge
        case .recordCategory: .tourRecordCategory
        case .recordCategoryNudge: .tourRecordCategoryNudge
        case .recordPerson: .tourRecordPerson
        case .recordPersonNudge: .tourRecordPersonNudge
        case .recordAccount: .tourRecordAccount
        case .recordAccountNudge: .tourRecordAccountNudge
        case .recordSave: .tourRecordSave
        case .recordSaveNudge: .tourRecordSaveNudge
        case .recordSaved: .tourRecordSaved
        case .recordReceipt: .tourRecordReceipt
        case .recordReceiptNudge: .tourRecordReceiptNudge
        case .recordReceiptReading: .tourRecordReceiptReading
        case .recordReceiptCheck: .tourRecordReceiptCheck
        case .recordReceiptSaved: .tourRecordReceiptSaved
        case .browsePrevious: .tourBrowsePrevious
        case .browsePreviousNudge: .tourBrowsePreviousNudge
        case .browseLastCycle(let month): .tourBrowseLastCycle(month)
        case .browseNextNudge: .tourBrowseNextNudge
        case .browseMonth: .tourBrowseMonth
        case .browseMonthNudge: .tourBrowseMonthNudge
        case .browseSearch: .tourBrowseSearch
        case .browseSearchNudge: .tourBrowseSearchNudge
        case .browseSearchType: .tourBrowseSearchType
        case .browseSearchTypeNudge: .tourBrowseSearchTypeNudge
        case .planLens: .tourPlanLens
        case .planLensNudge: .tourPlanLensNudge
        case .planIncome: .tourPlanIncome
        case .planHarian: .tourPlanHarian
        case .planRemaining: .tourPlanRemaining
        case .spotlightNudge: .tourSpotlightNudge
        case .insightsTab: .tourInsightsTab
        case .insightsTabNudge: .tourInsightsTabNudge
        case .insightsMakan: .tourInsightsMakan
        case .insightsMakanNudge: .tourInsightsMakanNudge
        case .insightsMakanFound: .tourInsightsMakanFound
        case .insightsLeaderboard: .tourInsightsLeaderboard
        case .insightsLeaderboardNudge: .tourInsightsLeaderboardNudge
        case .insightsIbuFirst: .tourInsightsIbuFirst
        }
    }
}
