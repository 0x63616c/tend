# Latest uploaded build: Tendr 1.0.0 (12)

September 11, 2026: build 12 uploaded successfully and Apple confirmed processing completed. Assignment to the existing **Owner Preview** internal group still needs direct verification; processing alone does not prove tester availability.

Future releases use the checked-in Fastlane lanes: `verify` runs the fast core suite, `ui` runs the full simulator flow suite when UI behavior changes, `beta` verifies then builds and uploads the next build before waiting and assigning it to Owner Preview, and `distribute_existing` assigns a processed build without rebuilding it. App Store Connect API-key values are supplied at runtime and never committed.

On the release Mac, the ignored `.env.tendr` file supplies `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_BETA_FEEDBACK_EMAIL`, and either `ASC_KEY_PATH` or `ASC_KEY_CONTENT`. The API key needs the App Manager role so Fastlane can assign builds to the internal group. Run `bundle exec fastlane --env tendr ios beta changelog:"Visible changes"`. Existing internal group members receive the new build without another invitation.

# Previous verified release: Tendr 1.0.0 (5)

September 10, 2026: build 5 uploaded successfully and verified Testing in the existing Owner Preview internal group. App name updated to Tendr: Dose & Weight Journal. See [build 5 notes](BUILD-5.md). Existing testers can update without another invitation. Physical build 5 installation is not verified.

# Release state

App: Tend: Dose & Weight Journal, Apple ID `6809098849`.
Bundle identifier: `com.calumwebb.still`.
Current TestFlight release: **1.0.0 (4)**, app source commit `e20c947`.

Build 4 uploaded successfully September 10, 2026 at 12:03 Pacific. App Store Connect completed processing and the existing **Owner Preview** internal group reports **Testing**, with one tester and builds 3 and 4 assigned. Build 4 has 90 days remaining. TestFlight release notes were submitted. This verifies availability to the existing group, not installation of build 4 on the physical iPhone.

The owner previously installed build 3 on September 7; this is an update, not a new invitation. Automatic distribution remains disabled. No App Store or external beta review was submitted.

Validation: 12 core tests and 8 UI tests passed. New Journal add/edit/cancel-delete/delete/relaunch regression was observed failing before implementation and passing afterward. Simulator: Tend QA Pro Max, iOS 26.2. Physical iOS 27 behavior is not covered by these tests. See [Build 4 changes and limits](BUILD-4.md).

Archive: `build/TendBuild4.xcarchive`. UI results: `Test-Still-2026.09.10_11-59-42--0700.xcresult`. Synthetic screenshots are in `docs/screenshots/build4-*.png`.

Build 1 predates the kilogram editor regression fix and must not be distributed. Builds 2 and 3 are superseded. The app remains local-first with no backend; the assistant is a coming-soon preview.
