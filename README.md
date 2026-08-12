# Access Toggle

_An iOS app that lets you flip a single switch to block or restore access to chosen apps on your iPhone._

Access Toggle is a SwiftUI app built on Apple's Screen Time APIs (`FamilyControls`, `ManagedSettings`). You pick which apps or app categories to manage, then use one switch to shield them (they show the system "blocked" screen when opened) or restore normal access instantly.

## How it works

| Framework | Role |
|---|---|
| `FamilyControls` | Requests the user's Screen Time consent (`AuthorizationCenter`) and provides the `familyActivityPicker` sheet used to choose apps/categories, without ever exposing their identities to this app's code. |
| `ManagedSettings` | Applies or lifts the actual shield via `ManagedSettingsStore.shield`. |
| `UserDefaults` | Persists your app/category selection and the current on/off state across launches. |

Source layout:

```
AppAccessToggle/
  project.yml                     # XcodeGen project spec (source of truth for the Xcode project)
  AppAccessToggle.entitlements    # com.apple.developer.family-controls
  Sources/
    AppAccessToggleApp.swift      # App entry point
    ContentView.swift             # Status, permission flow, the on/off toggle, app picker
    ScreenTimeManager.swift       # Authorization + shield logic
    SelectionStore.swift          # Persistence for selection + toggle state
  Resources/
    Assets.xcassets/              # Placeholder AppIcon + AccentColor
```

## Requirements

- Xcode 15 or newer (Xcode 16 recommended), iOS 16 deployment target
- **A physical iPhone.** The Screen Time APIs do not work in the iOS Simulator.
- An Apple Developer Program membership (paid). The Family Controls entitlement isn't available to free/personal-team accounts.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (recommended, not required): `brew install xcodegen`

## Getting it into Xcode

**Option A — XcodeGen (recommended):**

```bash
cd AppAccessToggle
xcodegen generate
open AppAccessToggle.xcodeproj
```

**Option B — manual:** Create a new Xcode project (App, Interface: SwiftUI, Language: Swift), delete its generated `ContentView.swift`/`...App.swift`, then drag in this repo's `Sources/` files and `Resources/Assets.xcassets`. In **Signing & Capabilities**, click **+ Capability** and add **Family Controls** — Xcode creates and wires up the entitlement for you automatically.

Either way, before building:

1. Change `PRODUCT_BUNDLE_IDENTIFIER` (in `project.yml`, or the target's Signing & Capabilities tab) to an identifier you own — it's currently a placeholder (`com.yourcompany.appaccesstoggle`).
2. Set your Team under Signing & Capabilities.
3. Build and run on a real iPhone signed into a normal (non-supervised) Apple ID, and approve the Screen Time permission prompt on first launch.

## Taking it to the App Store

Getting the capability into Xcode is enough for **development testing on your own device** — that part works immediately, no approval wait.

Shipping to TestFlight or the App Store is a separate step: Apple must approve a **Family Controls (Distribution)** request for your bundle ID before a build using this entitlement can go out publicly.

1. Submit the request at Apple's [Family Controls distribution request form](https://developer.apple.com/contact/request/family-controls-distribution), once per bundle ID. You'll need to describe a genuine parental-control or digital-wellbeing use case — Apple reviews these manually.
2. Turnaround has been reported anywhere from about 4 business days to several weeks; budget time for this before a launch date. Check the [Apple Developer Forums' Family Controls tag](https://developer.apple.com/forums/tags/family-controls) if a request seems stuck.
3. Once approved, enable **Family Controls** for your App ID under Identifiers in App Store Connect / the developer portal before archiving your submission build.

## Things worth knowing

- **App names are never exposed to this app's code, by design.** Screen Time deliberately keeps the identity of managed apps private from third-party code; `Label(token)` renders the system's own icon/name for a selected app without ever handing your code a bundle ID or string. That's expected behavior, not a bug.
- **No real app icon is included.** `Resources/Assets.xcassets/AppIcon.appiconset` has an empty 1024×1024 slot — drop in real artwork before submitting.
- **Manual toggle only, no scheduling.** This app blocks/allows access only when you flip the switch. If you want time-based auto-blocking (e.g. "block social apps after 10pm"), that needs a `DeviceActivityMonitor` app extension, which isn't included here.
- `ScreenTimeManager.applyShieldState()` has one call — `.specific(_:except:)` on `ShieldSettings.ActivityCategoryPolicy` — flagged with a `NOTE:` comment to double check against your Xcode SDK version; Apple has adjusted this API's exact shape across iOS releases and this was written without a Mac/Xcode available to compile-check it.
