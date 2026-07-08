# SprintCounter

> A macOS widget that tracks your sprint progress in working days.

![CI](https://github.com/aliab/macSprinitCounter/actions/workflows/ci.yml/badge.svg)
![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)
![macOS](https://img.shields.io/badge/platform-macOS%2015%2B-000000.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-F05138.svg)

![hero image](https://raw.githubusercontent.com/aliab/macSprinitCounter/refs/heads/main/art/top_banner.png)

SprintCounter is a lightweight macOS app + WidgetKit extension that shows the current sprint in a rolling quarter and how many working days you're into it. Configure your sprint start date, working days, sprint length, and sprints-per-quarter in the companion app; the widget reflects the current state on your desktop, Notification Center, or Home Screen.

## Features

- **Three widget sizes** — small, medium, and large, each tuned for its footprint.
- **Working-day-aware counting** — the day counter only ticks on your configured working days. Non-working days hold the last count until the next working day.
- **Rolling quarters** — quarters are derived from your first sprint start date, not the calendar. Q1 begins whenever sprint 1 begins.
- **Live preview** — the companion app shows a live widget preview as you edit config.
- **Per-day timeline refresh** — the widget timeline has an entry at the start of each remaining working day, so the counter ticks at midnight on working days without exceeding WidgetKit's refresh budget.
- **2026 visual style** — gradient container, single accent gradient, tabular numerals with `.numericText()` content transitions, subtle material layers.
- **Foundation-only engine** — sprint math lives in a pure Swift package with no UI dependencies, fully unit-tested.

## Requirements

| | Version |
|---|---|
| macOS | 15.0 (Sequoia) or later |
| Xcode | 16.0 or later |
| Swift | 6.0 |
| XcodeGen | 2.45.0 or later |

## Building from source

This repo uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate `SprintCounter.xcodeproj` from `project.yml`. The `.xcodeproj` is committed for convenience, but you can regenerate it any time.

```bash
# 1. Install XcodeGen (one time)
brew install xcodegen

# 2. Generate the Xcode project
xcodegen generate

# 3. Open in Xcode
open SprintCounter.xcodeproj
```

Or build from the command line:

```bash
xcodegen generate
xcodebuild build \
  -project SprintCounter.xcodeproj \
  -scheme SprintCounter \
  -configuration Debug \
  -destination "platform=macOS"
```

> **Forking?** The app and widget targets require an App Group (`group.com.aliabdolahi.sprintcounter`) and matching entitlements. Update the bundle ID prefix in `project.yml` and the App Group ID in `SprintEngineCore/Sources/SprintEngineCore/ConfigStore.swift` to your own.

## Usage

1. **Launch SprintCounter** — the companion app opens a config window.
2. **Configure your sprint:**
   - First sprint start date
   - Working days (Sun–Sat toggles — supports e.g. Sat–Wed working weeks)
   - Sprint length (1–4 weeks)
   - Sprints per quarter (1–12, default 6)
3. **Add the widget** — open Notification Center or the desktop widget gallery, search "Sprint Counter", and drag it to your desktop or Notification Center. Choose small, medium, or large.
4. The widget updates automatically at the start of each working day. If you change config in the app, the widget refreshes immediately.

## Architecture

```
SprintCounter.xcodeproj
├── SprintCounterApp/         macOS app target — companion + config UI
│   ├── SprintCounterApp.swift       @main App, first-launch defaults, widget reload
│   ├── ConfigWindow.swift           SwiftUI form + live preview
│   └── SprintPreviewCard.swift
├── SprintWidget/             Widget extension target
│   ├── SprintWidget.swift           Widget definition, TimelineProvider
│   ├── SprintWidgetViews.swift      Small / Medium / Large views
│   └── SprintTheme.swift            Gradient theme, progress bar
└── SprintEngineCore/         Swift package — pure date math, no UI deps
    └── Sources/SprintEngineCore/
        ├── SprintEngine.swift       currentSprint(today:config:) → SprintState
        ├── SprintConfig.swift       stored config (Codable, Sendable)
        ├── SprintState.swift        computed sprint state
        ├── ConfigStore.swift        App Group container persistence + UserDefaults fallback
        └── Weekday.swift
```

**Key design rule:** `SprintEngine` imports only `Foundation` — no AppKit, SwiftUI, or WidgetKit. This keeps it unit-testable and lets both the app and widget targets depend on it without pulling in each other's frameworks.

### Data flow

```
ConfigWindow (form)
      │  writes SprintConfig as JSON
      ▼
App Group container / sprintConfig.json
      │
      ├── read by ──> SprintWidget TimelineProvider
      │                      │
      │                      ▼
      │              SprintEngine.currentSprint(today) ──> SprintState
      │
      └── read by ──> ConfigWindow (live preview)
                             │
                             ▼
                     SprintEngine.currentSprint(today) ──> SprintState
```

On any config change, the app calls `WidgetCenter.shared.reloadAllTimelines()` for an immediate widget refresh.

## Configuration

Config is stored as JSON in the App Group container (`~/Library/Group Containers/group.com.aliabdolahi.sprintcounter/sprintConfig.json`), shared between the app and widget. An App Group `UserDefaults` store (`group.com.aliabdolahi.sprintcounter`, key `sprintConfig`) is kept in sync as a fallback. On first launch, default config (Mon–Fri, 2-week sprints, 6 sprints/quarter, start = today) is written automatically so the widget never shows a placeholder on fresh install.

A debug log is written to `sprintConfig-debug.log` in the same App Group container from the app process (not the widget) to help diagnose config issues.

## Testing

The sprint math is covered by unit tests in `SprintEngineCore/Tests/SprintEngineCoreTests/`. Run them from the command line:

```bash
cd SprintEngineCore
swift test --parallel
```

Or from Xcode: `⌘U` on the `SprintCounter` scheme.

Covered cases: mid-sprint working day, sprint boundary, non-working day (no increment), quarter rollover, pre-start, empty working-days (no divide-by-zero), config persistence.

## Roadmap

- [ ] iCloud sync
- [ ] iOS port
- [ ] Per-widget configuration via WidgetKit intents

## License

MIT — see [LICENSE](LICENSE).

Copyright (c) 2026 ali abdolahi.
