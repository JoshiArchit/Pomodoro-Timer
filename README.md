# 🍅 Pomodoro Timer

A Pomodoro timer for **iPhone and Apple Watch**, built with SwiftUI. The two apps stay in sync in real time via WatchConnectivity and share their timer logic through a common `PomodoroCore` Swift package.

## Overview

Pomodoro Timer helps you stay focused using the [Pomodoro Technique](https://en.wikipedia.org/wiki/Pomodoro_Technique) — 25 minutes of focused work followed by short breaks, with a longer break after every 4 sessions.

Start a session on your watch and it continues on your phone, and vice versa. Settings, timer state, and completed-session history are kept consistent across both devices.

## Screenshots

### watchOS

<p float="left">
    <img src="Screenshots/splash_screen.png" width="200" />
    <img src="Screenshots/focus.png" width="200" />
    <img src="Screenshots/short_break.png" width="200" />
    <img src="Screenshots/settings_1.png" width="200" />
    <img src="Screenshots/settings_2.png" width="200" />
</p>

## Features

- ⏱ Focus, short break, and long break timer cycles
- 📱⌚️ Companion iOS and watchOS apps sharing one codebase
- 🔄 Real-time sync across devices via `WatchConnectivity` — start, pause, or change settings on one device and the other follows
- 💍 Animated circular progress ring with phase color coding
- 🔔 Haptic feedback and local notifications on session completion, with dismissal synchronized across devices
- 📜 Session history tracking completed and skipped sessions
- ⚙️ Customizable durations via Settings
- 🔋 Background runtime on watchOS via `WKExtendedRuntimeSession` — timer keeps running when the wrist is lowered
- 🍅 Splash screen on launch

## Sync Architecture

State is synchronized using an **anchor-based** approach rather than per-second ticks:

- When the timer starts, a `phaseEndDate` anchor (`Date() + timeRemaining`) is set and shared once.
- Each device drives its own countdown display locally from that anchor, so backgrounding one device never freezes the other.
- A `sessionID` changes on every phase advance, letting either device detect and dedupe double-completions.
- Settings and timer state ride over `updateApplicationContext`; notification dismissals over `transferUserInfo`.

## Platforms

| Platform | Status      |
| -------- | ----------- |
| watchOS  | ✅ Complete |
| iOS      | ✅ Complete |
| iPadOS   | 📋 Planned  |
| macOS    | 📋 Planned  |

## Requirements

- Xcode 16+
- iOS 17+
- watchOS 10+
- Swift 6

## Project Structure

```
PomodoroTimer/
├── PomodoroCore/                    ← shared Swift package (iOS + watchOS)
│   └── Sources/PomodoroCore/
│       ├── PomodoroState.swift      ← state model + cycle logic + settings
│       ├── SessionRecord.swift      ← completed/skipped session model
│       ├── ConnectivityPayload.swift← WatchConnectivity keys + timer payload
│       └── ProgressRing.swift       ← shared circular progress component
│
├── PomodoroTimer/                   ← iOS app
│   ├── PomodoroTimerApp.swift       ← entry point
│   ├── ContentView.swift            ← root / tab coordinator
│   ├── TimerView.swift              ← timer UI
│   ├── SettingsView.swift           ← customizable durations
│   ├── HistoryView.swift            ← session history
│   ├── SplashView.swift             ← launch splash
│   ├── TimerManager.swift           ← timer logic + notifications
│   └── ConnectivityManager.swift    ← WatchConnectivity bridge
│
├── Pomodoro Watch App/              ← watchOS app
│   ├── PomodoroWatchApp.swift       ← entry point
│   ├── RootView.swift               ← splash coordinator
│   ├── ContentView.swift            ← TabView coordinator
│   ├── TimerView.swift              ← timer UI
│   ├── SettingsView.swift           ← customizable durations
│   ├── SplashView.swift             ← launch splash
│   ├── TimerManager.swift           ← timer logic + background session
│   └── ConnectivityManager.swift    ← WatchConnectivity bridge
│
├── PomodoroWatchAppTests/           ← unit tests
└── PomodoroWatchAppUITests/         ← UI tests
```

## Architecture

- **`PomodoroCore`** — a shared Swift package imported by both apps. Holds the pure-Swift `PomodoroState` (all timer state and cycle logic), `PomodoroSettings`, `SessionRecord`, the WatchConnectivity payloads, and the shared `ProgressRing` view.
- **`TimerManager`** — per-platform `ObservableObject` managing the timer, haptics, notifications, persistence (`UserDefaults`), and (on watchOS) the background runtime session.
- **`ConnectivityManager`** — per-platform `WCSessionDelegate` that sends and receives settings, timer state, session history, and notification dismissals.
- Views are driven by `TimerManager` shared via `EnvironmentObject`.

## Pomodoro Technique

| Phase                      | Default Duration |
| -------------------------- | ---------------- |
| Focus                      | 25 minutes       |
| Short Break                | 5 minutes        |
| Long Break                 | 15 minutes       |
| Sessions before long break | 4                |

All durations are customizable via the Settings screen.

## Branch Strategy

```
main          ← stable, protected
feat/*        ← feature branches, merged via PR
fix/*         ← fix branches, merged via PR
```

Direct pushes to `main` are blocked. All changes go through a pull request.

## Built With

- SwiftUI
- WatchKit
- WatchConnectivity
- Combine
- UserNotifications
- XCTest / Swift Testing

## Author

Archit Joshi — learning iOS/watchOS development through [100 Days of SwiftUI](https://www.hackingwithswift.com/100/swiftui)

## License

[MIT](LICENSE)
</content>
</invoke>
