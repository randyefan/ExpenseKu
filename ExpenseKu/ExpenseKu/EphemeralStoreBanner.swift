//
//  EphemeralStoreBanner.swift
//  ExpenseKu
//
//  Shown when the store failed to open and the app is running on the in-memory
//  fallback. The owner has to know *before* they log anything, because an ephemeral
//  store behaves exactly like a working one until the app quits and takes everything
//  with it.
//

import SwiftUI

struct EphemeralStoreBanner: View {
    var body: some View {
        HStack(spacing: Metric.cardGap) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("Storage unavailable — expenses won’t be saved.")
                .font(.dsSubhead)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Metric.screenPadding)
        .padding(.vertical, Metric.cardGap)
        .background(Theme.accent)
    }
}
