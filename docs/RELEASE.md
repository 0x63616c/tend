# Release state

App Store Connect app: Tend: Dose & Weight Journal, Apple ID `6809098849`.
Bundle identifier: `com.calumwebb.still` (the original internal project name).
Version/build: `1.0.0 (1)`.

The candidate archive at `build/TendCandidate.xcarchive` includes the flat Discover design and the tested dose unit-switching correction at commit `74ac4ed`. Signing and archive succeeded. Apple accepted the upload on September 5, 2026 at 20:31 Pacific and reported that processing had begun. Tester availability still needs verification. Build 1 should not be enabled for testers: a subsequently reproduced kilogram-editor initialization bug is being corrected in build 2. Do not equate the public repository, archive or export with a TestFlight release.

The application has no backend. The assistant is explicitly a preview. Before broad beta distribution, complete the open checks in `TESTING.md`, including actual notification delivery and complete record create/edit/relaunch flows.

Build 2 is archived at `build/TendBuild2.xcarchive` from commit `aaeb78c`, including both passing UI regression fixes. Its App Store Connect upload has been started. Build 1 remains unsuitable for tester distribution because of the kilogram editor issue.
