import SwiftUI

struct LanguageChoices: View {
    let selected: AppLanguage
    let onSelect: (AppLanguage) -> Void

    @ScaledMetric(relativeTo: .body) private var flagWidth: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var flagHeight: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var selectionWidth = Metric.cardPadding

    var body: some View {
        VStack(spacing: 0) {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    onSelect(language)
                } label: {
                    HStack(spacing: Metric.cardGap) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Theme.accent)
                            .opacity(selected == language ? 1 : 0)
                            .frame(width: selectionWidth)
                            .accessibilityHidden(true)
                        Group {
                            switch language {
                            case .system:
                                Image(systemName: "globe")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: flagHeight)
                                    .foregroundStyle(Theme.textSecondary)
                            case .indonesian:
                                Image(.languageFlagIndonesia)
                                    .resizable()
                                    .scaledToFit()
                            case .english:
                                Image(.languageFlagUk)
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                        .frame(width: flagWidth, height: flagHeight)
                        .accessibilityHidden(true)
                        Text(language.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .font(.dsBody)
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, Metric.cardPadding)
                    .padding(.vertical, Metric.cardGap)
                    .frame(minHeight: 52)
                    .contentShape(.rect)
                }
                .buttonStyle(.pressableRow)
                .accessibilityLabel(language.title)
                .accessibilityAddTraits(selected == language ? .isSelected : [])
                .accessibilityIdentifier("languageChoice.\(language.rawValue)")

                if language != AppLanguage.allCases.last {
                    Divider().overlay(Theme.hairline)
                }
            }
        }
        .frame(width: 300)
    }
}
