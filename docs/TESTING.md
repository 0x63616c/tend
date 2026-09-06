# Verification log

## Core

`swift test` passes 11 tests after the journal compatibility change. The new compatibility test failed on the older minimal journal fixture before implementation, then passed after default decoding was added. It also rejects an unknown future schema version. This verifies decoding, not the UI recovery experience.

Covered: weight chronology and future filtering, future taken-dose rejection, local weekday scheduling across daylight saving, journal round-trip and historical medication snapshots, overdue resolution, explicit syringe scale conversion, half-life arithmetic, decimal entry validation, goal pace and check-in rating bounds.

## UI

The Discover walkthrough passed (one test, zero failures; `build/DiscoverQA.xcresult`) on a separate iPhone 17 Pro Max simulator. It exercises navigation, dose sheet presentation, Progress, Journal, Discover filtering and opening a recipe. This is not yet a complete create/edit/relaunch regression suite.

## Remaining release checks

- Full record create/edit/relaunch journeys and recovery after unreadable storage.
- Actual notification delivery and permission-denial handling.
- Accessibility, larger text, light/dark visual review and final screenshot curation.
- Signing, archive, App Store Connect upload and verified TestFlight availability.

## Dose unit switching regression

The simulator test `testChangingDoseUnitsPreservesTheDose` reproduced two failures: entering 3 U-100 units and selecting mg or mL kept the literal number 3. The selector now converts through the dose's concentration and preserves its amount (3 units = 0.15 mg = 0.03 mL at 5 mg/mL). If required conversion information is absent, it clears the input instead of reinterpreting it.

Xcode 26.2's Swift 6.2.3 compiler crashed in IR generation with a direct method reference used as the binding setter. An explicit closure compiles successfully. The same UI regression test is retained to verify the behaviour.

Verification: targeted UI test passed with zero failures in `Test-Still-2026.09.05_20-26-19--0700.xcresult`; `swift test` also passed after the change.

## Kilogram editor regression

After selecting kilograms in Settings, reopening the synthetic 88.5 kg journal entry displayed 40.14 kg. The UI test reproduced this exact mismatch. Initialization was triggering the unit-change observer and converting the loaded value twice. Conversion now occurs only through the unit picker's user-driven setter; loading an entry preserves its recorded amount. Editable weight values omit grouping separators and retain up to eight decimal places.

Verification: the kilogram UI regression passed in `Test-Still-2026.09.05_20-32-11--0700.xcresult`.
