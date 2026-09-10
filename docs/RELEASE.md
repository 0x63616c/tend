# Release state

App: Tend: Dose & Weight Journal, Apple ID `6809098849`.
Bundle identifier: `com.calumwebb.still`.
Current TestFlight release: **1.0.0 (4)**, app source commit `e20c947`.

Build 4 uploaded successfully September 10, 2026 at 12:03 Pacific. App Store Connect completed processing and the existing **Owner Preview** internal group reports **Testing**, with one tester and builds 3 and 4 assigned. Build 4 has 90 days remaining. TestFlight release notes were submitted. This verifies availability to the existing group, not installation of build 4 on the physical iPhone.

The owner previously installed build 3 on September 7; this is an update, not a new invitation. Automatic distribution remains disabled. No App Store or external beta review was submitted.

Validation: 12 core tests and 8 UI tests passed. New Journal add/edit/cancel-delete/delete/relaunch regression was observed failing before implementation and passing afterward. Simulator: Tend QA Pro Max, iOS 26.2. Physical iOS 27 behavior is not covered by these tests. See [Build 4 changes and limits](BUILD-4.md).

Archive: `build/TendBuild4.xcarchive`. UI results: `Test-Still-2026.09.10_11-59-42--0700.xcresult`. Synthetic screenshots are in `docs/screenshots/build4-*.png`.

Build 1 predates the kilogram editor regression fix and must not be distributed. Builds 2 and 3 are superseded. The app remains local-first with no backend; the assistant is a coming-soon preview.
