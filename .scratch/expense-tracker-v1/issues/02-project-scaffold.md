# 02 — Project scaffold: SwiftUI multiplatform + SwiftData + CloudKit

Status: needs-info
Blocked by: 01

Create the Xcode project and wire up persistence + sync.

## Scope

- SwiftUI **multiplatform app target** (iOS 17 / iPadOS 17 / macOS 14 floor).
- SwiftData `ModelContainer` configured with **CloudKit** private-database mirroring.
- Entitlements: iCloud + CloudKit, background modes as needed; matching container identifier.
- App builds and runs empty on all three platforms.

## Definition of done

- Project builds for iOS and macOS.
- A trivial SwiftData model round-trips and syncs across two signed-in devices/simulators.

## Comments
