# Release state

App Store Connect app: Tend: Dose & Weight Journal, Apple ID `6809098849`.
Bundle identifier: `com.calumwebb.still` (the original internal project name).
Current candidate: **1.0.0 (3)**, source commit `08061f4`.

Build 3 was archived at `build/TendBuild3.xcarchive` and uploaded successfully on September 5, 2026 at 20:50 Pacific. App Store Connect subsequently reported **Ready to Test**. Owner Preview has one tester, the account holder. Build 3 is now assigned to Owner Preview and its group status is **Testing**, with one account-holder tester. TestFlight What to Test notes were saved. The tester row subsequently changed to **Invited**, verified directly in App Store Connect. This confirms the owner invitation is available; installation on the owner's physical iPhone has not been observed. Accept the invitation in TestFlight to install version 1.0.0 (3).

Build 1 must not be distributed: it predates the kilogram editor regression fix. Build 2 includes both unit-conversion fixes but is superseded by build 3, which also contains the real notification preview, empty initial schedule and graph detail close control. Automatic distribution is disabled.

The application has no backend. The assistant is explicitly a coming-soon preview. See TESTING.md for completed verification and remaining coverage limits.
