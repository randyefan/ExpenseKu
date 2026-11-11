# Indonesian and English localization

Status: Built

## Scope

Localize the app and receipt share extension into Indonesian and English. Follow the device's preferred supported language by default; English remains the development language and fallback. Manage includes a Language menu with Follow Device Language, Bahasa Indonesia, and English.

Use manually managed String Catalog keys and generated Swift symbols. Translate interface text, accessibility descriptions, dynamic messages, confirmations, and empty states. Preserve currency as IDR and existing whole-rupiah precision. Combine the selected language with the device's region, calendar, and hour-cycle preferences for formatting.

Selecting a language applies immediately, without restarting the app or recreating its root view. Preserve the selected tab, navigation paths, cycle, filters, and unsaved input. Store the selection on this device in the existing App Group preferences so that newly opened receipt share extensions use the same language. Unsupported or missing saved choices fall back to Follow Device Language. This preference does not sync through CloudKit.

User-created category, group, person, account, plan-item, income-line names, and notes remain unchanged. The protected owner entry displays Saya or Me based on its isMe flag; its stored name and identity do not change. Persistence schema, CloudKit records, receipt recognition languages, and AI extraction prompts do not change.

## Approved terminology

| English | Indonesian |
| --- | --- |
| Expenses | Pengeluaran |
| Insights | Analisis |
| Manage | Kelola |
| Plan | Rencana |
| Income | Pemasukan |
| Remaining | Sisa |
| Account | Sumber dana |
| Category / Group | Kategori / Grup |
| People / Me | Orang / Saya |
| Envelope | Pos anggaran |
| Fixed | Pembayaran |
| Auto | Otomatis |
| Funded | Dana siap |
| Set aside | Sisihkan |
| Paid early | Dibayar lebih awal |
| Paid elsewhere | Dibayar dari sumber lain |
| Outside plan | Di luar rencana |
| Needs review | Perlu diperiksa |
| Receipt | Bukti pembayaran |

Done closes a panel as Selesai, and names a completed payment as Sudah dibayar. Set aside names an action as Sisihkan and allocated money as Dana sisihan. Whole sentences are translated with placeholders and count-dependent variants; English suffixes and grammar must not be applied to Indonesian text.

## Validation

- Build the app and share extension with Xcode 27.2.
- Run existing unit tests in Debug and Release.
- Test Indonesian and English resources, plural messages, destructive confirmations, and the distinction between funded and paid.
- Verify both languages in an isolated simulator with seeded sample data. Check the expense list, plan, editor, management screens, and receipt strings, including accessibility text.
- Check longer Indonesian labels for clipping and truncation.

## Decisions

The owner approved the terminology, Indonesian and English scope, unchanged user data, and IDR currency in this conversation, then requested an in-app language entry point that works without restarting. The Language row uses the existing ManageMenuRow and card styling. The owner subsequently selected AJ3A Leading Flags UK: Indonesia and UK flags precede their language names, the device option uses a globe, and the selected option retains a checkmark. The entry point is shown in AJ1 Manage Language Entry and the approved choices in AJ3A on the ExpenseKu Proposals page in Wonder.

## Implementation

The app and share extension each have their own String Catalog, containing 574 and 7 manually managed keys respectively. Xcode generates the Swift resource symbols for both targets. The English interface uses Remaining wherever the previous mixed-language interface used Sisa.

LanguageSettings is an observable, Sendable preference store with main-actor mutations and mutex-protected reads. Pure nonisolated derivations can read the same choice safely. AppLocalization resolves generated resources using the current selection, and LocalizedText provides the corresponding Text initializer. Both targets compile these shared files. Language-dependent static labels and icon-group titles are computed rather than cached at first use.

The root supplies the selected locale through SwiftUI's environment, while explicitly formatted date and money strings use the same locale. The implementation neither changes AppleLanguages nor replaces Bundle behavior, and does not use a changing root identity to force an update. Refreshing on activation picks up shared preferences and current device locale settings.

LanguageMenu is the setting entry point. ManageMenuRow gains an accessory symbol parameter so it can show a menu chevron while retaining the existing row and icon styling. LanguageChoices renders the approved leading-flag layout inside a SwiftUI popover, with selected accessibility traits and decorative images hidden from VoiceOver. Selecting a row dismisses the popover and applies the preference immediately. The system provides popover positioning, dismissal, and chrome.

The Indonesia and UK PNG images are bundled in Assets.xcassets/LanguageFlags from the approved Wonder artwork, so the chooser works offline. Flags retain their original colors and proportions. The 300-point chooser width, 52-point minimum row height, and 28-by-20-point marker slot follow AJ3A where no existing repository token applies; marker and checkmark sizes scale with Dynamic Type. Spacing, fonts, and colors use the existing Metric, design-system fonts, and Theme values. Flag choice is presentation only and does not change the selected region or IDR currency.

Plan counts use a typed PlanCount noun and catalog plural variants. Destructive confirmations translate complete sentences rather than inserting English verbs or possessives into Indonesian text. Separate keys distinguish closing a sheet from completing a payment, and a set-aside action from allocated funds.

The existing SegmentedToggle now chooses a stacked icon-and-label layout when its compact horizontal layout does not fit. SegmentedToggleOptions contains the shared rendering and selection behavior for both layouts. This keeps Indonesian kind labels legible without splitting Pembayaran or removing the icons.

## Verification notes

Verified on 11 November 2026 with Xcode 27.2 and a dedicated iPhone 18 Pro simulator running iOS 27.2. Both target catalogs compile, have translations for every key, and use matching placeholder types in both languages.

Simulator checks covered the plan in Indonesian and English, the Indonesian plan editor, expense editor, Manage screen, and receipt-reading screen. The Manage screen was also checked with an accessibility text size. Screenshots are available during this worktree session under /tmp/expenseku-localization-shots/.

Locale-sensitive legacy tests now format expected IDR amounts using the current locale and use explicit locales when asserting a particular date layout. LocalizationTests separately verifies Indonesian and US English money separators, IDR currency, month names, plural counts, preservation of stored names, and resource completeness for both targets.

LanguageSettingsTests adds 11 tests covering preference persistence, supported device-language matching, preserved region/calendar/hour cycle, existing resources resolving in a newly selected language, Observation invalidation, repeated selection, shared-preference refresh, background reads, changing previously cached labels, and unchanged stored person names.

Live simulator verification switched English to Indonesian and back with the same running process. The existing plan lens and Name sorting remained selected, and Insights retained its This year filter. A separate deliberate relaunch with an English device language retained the saved Indonesian selection; choosing Follow Device Language then immediately restored English. The Indonesian Language entry also remained readable and reachable at an accessibility text size.

The AJ3A flag chooser was verified in the simulator in English and Indonesian. Both bundled flags appear before the names with their original colors and proportions, and the selected row exposes the selected accessibility trait without announcing decorative images. Choosing Indonesian, English, and Follow Device Language dismisses the popover and updates the interface without restarting the process. Tapping outside dismisses it without changing the choice. An accessibility-large text-size check confirmed wrapping, scaled markers, and readable selection. Screenshots are flag-picker-en.png, flag-picker-id.png, and flag-picker-accessibility.png under the session screenshot directory.

The Release suite uses the same Release configuration and ENABLE_TESTABILITY=YES as scripts/test-release.sh, with an explicit isolated simulator, build directory, language, and region.

| Check | Result |
| --- | --- |
| Debug unit suite, English / US region | 697 passed, 0 failures |
| Release unit suite, English / US region | 697 passed, 0 failures |
| LocalizationTests and LanguageSettingsTests, Indonesian / Indonesia region, Release | 22 passed, 0 failures |
| Translation and placeholder coverage | All 581 keys have both languages and matching argument positions and types |
| Simulator visual checks | Passed, including adaptive plan-kind labels and accessibility-size Manage and Language rows |
| Live switching and persistence | Passed; process unchanged during switching, retained plan sort and Insights filter, saved selection restored on relaunch |
| AJ3A leading flags | Passed; Indonesia/UK assets, device globe, selected accessibility state, outside dismissal, live switching, and accessibility-large text |

The build still reports three existing actor-isolation warnings in PeopleLeaderboardTests. These are outside the localization changes. SwiftLint is not installed; Xcode compilation and git diff whitespace checks pass.
