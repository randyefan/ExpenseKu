import SwiftUI

struct LanguageMenu: View {
    @Environment(LanguageSettings.self) private var settings
    @State private var showsChoices = false

    var body: some View {
        Button {
            showsChoices = true
        } label: {
            ManageMenuRow(
                title: AppLocalization.string(.language), systemImage: "globe",
                subtitle: settings.language.title, tint: Theme.accent,
                accessory: "chevron.down"
            )
        }
        .buttonStyle(.pressableRow)
        .accessibilityIdentifier("languageMenu")
        .padding(.horizontal, Metric.cardPadding)
        .cardStyle(padding: 0)
        .popover(isPresented: $showsChoices, arrowEdge: .bottom) {
            LanguageChoices(selected: settings.language) { language in
                showsChoices = false
                settings.select(language)
            }
            .presentationCompactAdaptation(.popover)
            .presentationBackground(Theme.surface)
        }
    }
}
