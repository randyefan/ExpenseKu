//
//  AppVersionFooter.swift
//  ExpenseKu
//
//  The signature and build number at the foot of the Manage tab.
//

import SwiftUI

struct AppVersionFooter: View {
    var body: some View {
        VStack(spacing: 2) {
            Text("Made By REJ ❤️")
                .font(.dsCaption).fontWeight(.semibold)
                .foregroundStyle(Theme.textSecondary)
            Text("Version \(Self.appVersion)")
                .font(.dsCaption)
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Metric.cardGap)
    }

    static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}
