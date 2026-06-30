# Sprint Counter — macOS Widget Design

**Date:** 2026-06-30
**Target:** macOS 15 (Sequoia) and later
**Status:** Approved (pre-implementation)

## 1. Overview

A macOS app + WidgetKit widget extension that shows the current sprint in a rolling quarter and how many working days into that sprint we are. The user configures the first sprint start date, working days, sprint length, and sprints-per-quarter in a companion app; the widget reflects the current state on the Home Screen / Notification Center / desktop.

## 2. Requirements (confirmed)

- macOS widget built with SwiftUI + WidgetKit, targeting macOS 15+ (Sequoia).
- Companion macOS app (standard window, Dock-based) for configuration.
- All three widget sizes: small, medium, large.
- Config is shared between app and widget via App Group `UserDefaults`.
- Rolling quarters starting from the configured first sprint date (not calendar quarters).
- Working days per sprint are **derived** from the working-day set × sprint length in weeks — not set explicitly.
- Working days configured as per-day checkboxes (Sun–Sat), to support e.g. Sat–Wed working weeks.
- Sprints per quarter is a fixed, user-configured count (default 6).
- Widget shows: sprint number in quarter, days passed in current sprint, progress bar, percentage, working days left. Large widget additionally shows next sprint + its start date.
- Visual style: modern 2026 trend — gradient container background, single accent gradient, tabular numerals with `numericText` content transitions, subtle material layers.

## 3. Architecture

**Approach:** Shared `SprintEngine` (pure Swift) + App Group `UserDefaults`. The widget recomputes sprint state from the current date on each timeline refresh; the app calls `WidgetCenter.shared.reloadAllTimelines()` on config change for an immediate update.

### 3.1 Bundle structure

```
SprintCounter.xcodeproj
├── SprintCounterApp/              (macOS app target — companion + config UI)
│   ├── SprintCounterApp.swift     (@main App, main window)
│   ├── ConfigWindow.swift         (SwiftUI form + live preview)
│   ├── Info.plist
│   └── Assets.xcassets
├── SprintWidget/                  (Widget extension target)
│   ├── SprintWidget.swift         (Widget definition, TimelineProvider, views)
│   ├── Info.plist
│   └── Assets.xcassets
└── Shared/                        (linked into both targets)
    ├── SprintEngine.swift         (pure date math — no UI deps)
    ├── SprintConfig.swift         (config struct + Codable + App Group load/save)
    └── SprintState.swift          (computed: current sprint, day index, etc.)
```

### 3.2 Data flow

```
ConfigWindow (form)
      │  writes SprintConfig as JSON
      ▼
UserDefaults(suiteName: "group.com.aliabdolahi.sprintcounter")
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

On any config change, the app calls `WidgetCenter.shared.reloadAllTimelines()`.

### 3.3 Key design rule

`SprintEngine` imports only `Foundation` — no AppKit, SwiftUI, or WidgetKit. This keeps it unit-testable and lets both targets depend on it without pulling in each other's frameworks.

## 4. Data model

### 4.1 SprintConfig (stored)

```swift
struct SprintConfig: Codable {
    var firstSprintStart: Date          // midnight, local time, of sprint #1 day 1
    var workingDays: Set<Weekday>       // e.g. {.sat, .sun, .mon, .tue, .wed}
    var sprintLengthWeeks: Int           // e.g. 2
    var sprintsPerQuarter: Int          // e.g. 6
}
```

`Weekday` wraps `Calendar` weekday units (1 = Sunday … 7 = Saturday).

### 4.2 SprintState (computed)

```swift
struct SprintState {
    var sprintIndex: Int                // 0-based global sprint index since firstSprintStart
    var sprintInQuarter: Int            // 1-based, e.g. 3 (Sprint 3 of 6)
    var quarterIndex: Int               // 0-based quarter index
    var quarterNumber: Int              // 1-based (Q1, Q2, ...)
    var sprintStart: Date
    var sprintEnd: Date                 // exclusive; sprint N+1 starts here
    var workingDaysElapsed: Int         // counts today if today is a working day in this sprint
    var workingDaysInSprint: Int        // derived: workingDays.count × sprintLengthWeeks
    var workingDaysRemaining: Int       // workingDaysInSprint - workingDaysElapsed
    var progress: Double                // 0.0 – 1.0, workingDaysElapsed / workingDaysInSprint
    var nextSprintStart: Date           // sprintEnd (same instant)
    var status: SprintStatus            // .notStarted | .active | .noConfig
}
```

## 5. SprintEngine date math

`SprintEngine.currentSprint(today: Date, config: SprintConfig) -> SprintState`

All comparisons use a `Calendar` with the user's locale and time zone so "today" is unambiguous.

1. **Days since start:**
   `daysSinceStart = calendar.dateComponents([.day], from: firstSprintStart, to: today).day`
   Whole calendar days elapsed. Because `firstSprintStart` is anchored at midnight local time, this counts midnight-to-midnight crossings. (We use days, not `weekOfYear`, to avoid depending on the calendar's `firstWeekday` setting — that would shift the sprint boundary relative to the anchor.)

2. **Sprint index (0-based, floored):**
   `sprintIndex = daysSinceStart / (7 × sprintLengthWeeks)` (integer division)

3. **Sprint boundaries:**
   - `sprintStart = calendar.date(byAdding: .day, value: sprintIndex × sprintLengthWeeks × 7, to: firstSprintStart)`
   - `sprintEnd = calendar.date(byAdding: .day, value: sprintLengthWeeks × 7, to: sprintStart)` (exclusive; sprint N+1 starts here)

4. **Working days elapsed (count today if it's a working day):**
   Iterate over each calendar day from `sprintStart`'s date up to and including `today`'s date (compare dates only, not times). For each day, if its weekday ∈ `workingDays`, increment the counter. The time-of-day of `today` does not affect the count — we count calendar days.

5. **Derived totals:**
   - `workingDaysInSprint = workingDays.count × sprintLengthWeeks`
   - `progress = workingDaysElapsed / workingDaysInSprint` (guard divide-by-zero when workingDays is empty)

6. **Quarter:**
   - `quarterIndex = sprintIndex / sprintsPerQuarter` (integer division)
   - `sprintInQuarter = (sprintIndex % sprintsPerQuarter) + 1` (1-based)
   - `quarterNumber = quarterIndex + 1`

### 5.1 Day-counting convention

Count **today** as the current working day when today is a working day inside the sprint. So on a working day that is the 5th elapsed working day of an 8-working-day sprint, the widget reads "Day 5 of 8". On a non-working day (weekend), the counter does not increment — it shows the last working day's count until the next working day arrives.

### 5.2 Edge cases

| Case | Behavior |
|------|----------|
| `today` before `firstSprintStart` | `status = .notStarted`; widget shows "Sprint 1 starts `<date>`" |
| `today` is a non-working day | Sprint is still current; working-days-elapsed reflects last working day's count |
| `today` exactly on sprint boundary | New sprint is current; working-days-elapsed = 1 if today is a working day, else 0 |
| `workingDays` empty | `workingDaysInSprint = 0`; widget shows the sprint number but a degenerate progress bar (guard divide-by-zero) |
| Config not yet set in App Group | `status = .noConfig`; widget shows "Open SprintCounter to configure" |

## 6. Widget UI

### 6.1 Visual language (2026 trend)

- **Container:** `.containerBackground` with a vertical gradient — deep indigo → soft violet in dark mode, soft periwinkle → cream in light mode.
- **Typography:** SF Pro Rounded. Large `monospacedDigit()` tabular numerals for sprint number and day count. `.contentTransition(.numericText())` so the day counter animates when it ticks.
- **Accent:** a single indigo→pink gradient used only for the progress bar and sprint number. All other text stays neutral so the accent pops.
- **Depth:** a faint `.ultraThinMaterial` layer behind the progress bar.
- **No emoji, no stock icons** — just type, a thin progress bar, and the container gradient.

### 6.2 Small widget

```
┌───────────────┐
│  SPRINT 3/6   │
│               │
│   Day 5       │
│   of 8        │
│   ▓▓▓░░░░░    │
└───────────────┘
```

### 6.3 Medium widget

```
┌───────────────────────────────────┐
│ SPRINT 3 OF 6          Q2         │
│                                   │
│ Day 5 / 8                         │
│                                   │
│ ▓▓▓░░░░░░░░░░░░░░                 │
│ 62% · 3 working days left         │
└───────────────────────────────────┘
```

### 6.4 Large widget

```
┌─────────────────────────────────────┐
│ SPRINT 3 OF 6                Q2     │
│                                     │
│      Day 5                          │
│      of 8                           │
│                                     │
│ ████████████░░░░░░░░░░░░░░          │
│ 62% · 3 working days left           │
│                                     │
│ Next: Sprint 4 · starts Jul 13      │
└─────────────────────────────────────┘
```

### 6.5 Placeholder states

- **No config:** centered "Open SprintCounter to configure" text, dimmed styling.
- **Before first sprint start:** "Sprint 1 starts `<date>`" with progress bar at 0%.

### 6.6 Refresh strategy

`TimelineProvider` returns entries for: now, plus one entry at the start of each remaining working day in the current sprint, plus an entry at the next sprint boundary. Policy: `.atEnd`. This stays within WidgetKit's refresh budget while ensuring the day counter ticks at midnight local time on working days. On config change, the app calls `WidgetCenter.shared.reloadAllTimelines()` for immediate update.

## 7. Companion app

### 7.1 Shape

Standard window app, Dock-based. Single window with the config form on the left and a live widget preview on the right that updates as the user edits.

### 7.2 Config form fields

1. **First sprint start date** — `DatePicker`, date only.
2. **Working days** — 7 toggles in a row: Sun Mon Tue Wed Thu Fri Sat.
3. **Sprint length** — segmented control: 1 / 2 / 3 / 4 weeks.
4. **Sprints per quarter** — `Stepper`, 1–12, default 6.
5. **Live preview** — mock widget that calls `SprintEngine.currentSprint(today: Date())` on every edit.

### 7.3 Persistence & widget reload

- On any field change, encode `SprintConfig` to JSON and write to `UserDefaults(suiteName: "group.com.aliabdolahi.sprintcounter")` under key `sprintConfig`.
- Then call `WidgetCenter.shared.reloadAllTimelines()`.
- On first launch with no stored config, prefill defaults (first sprint = today, working days = Mon–Fri, 2-week sprints, 6 sprints/quarter) and save them, so the widget never shows the no-config placeholder on fresh install.

## 8. Testing

`SprintEngine` is covered by a unit test target (`SprintCounterTests`). Cases:

1. **Mid-sprint, working day:** Sat–Wed working week, 2-week sprints, today = a Wednesday mid-sprint → assert correct `sprintIndex`, `sprintInQuarter`, `workingDaysElapsed`, `progress`.
2. **Sprint boundary:** today = first day of a new sprint → `workingDaysElapsed` = 1 if today is a working day, else 0.
3. **Non-working day:** today = Thursday (weekend in Sat–Wed config) → `workingDaysElapsed` equals last working day's count (does not increment).
4. **Quarter rollover:** today = first sprint of a new quarter → `sprintInQuarter` = 1, `quarterNumber` increments.
5. **Pre-start:** today before `firstSprintStart` → `status = .notStarted`, correct "starts" date.
6. **Missing config:** no config in App Group → `status = .noConfig`.
7. **Empty working-days set:** `workingDaysInSprint = 0`, no divide-by-zero crash, widget still renders sprint number.

## 9. Out of scope (YAGNI)

- No calendar-quarter alignment (rolling quarters only).
- No iCloud sync.
- No per-widget configuration via WidgetKit intents (single global config shared by all widget instances).
- No backend / network calls.
- No iOS port (macOS only for now).
- No multi-team / multi-project support.

## 10. Open items

None. All decisions confirmed during brainstorming.
