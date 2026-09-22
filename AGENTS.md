# Project agent memory

- Start with [README.md](README.md) for build/test commands and contribution rules; Xcode configuration is owned by `project.yml` and the checked-in `Still.xcodeproj`.
- Core logic/tests: `Still/Core` and `Tests`; native UI/tests: `Still/Features` and `StillUITests`. `swift test` is the fast core gate. Simulator builds require Xcode 26.2 or later.
- Release entrypoint: `fastlane/Fastfile`. [docs/RELEASE.md](docs/RELEASE.md) documents automatic main-branch TestFlight delivery, required secrets, local signing, and recovery. `.github/workflows/testflight.yml` owns CI setup; `ruby scripts/check-release.rb` verifies lane mechanics without Apple credentials.
- Keep credentials, signing assets, and personal health data out of commits. Passing local tests or uploading an IPA does not prove TestFlight processing or internal-group availability.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
