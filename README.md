# Flixsy

A Flutter TV remote control app for iOS and Android. Communicates with TVs via the ConnectSDK native library through Flutter Platform Channels. Supports multiple visual skins, user-editable custom layouts, full localization across 12 languages, Riverpod state management, Drift local persistence, Firebase Analytics, and AdMob.

---

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure Firebase

Download the config files from the [Firebase Console](https://console.firebase.google.com/) for project **1:369433288413**.

| Platform | File | Destination |
|----------|------|-------------|
| Android | `google-services.json` | `android/app/google-services.json` |
| iOS | `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` |

**Firebase App IDs**

| Platform | App ID |
|----------|--------|
| Android | `1:369433288413:android:e172cb6b49330133924534` |
| iOS | `1:369433288413:ios:6839c26d6cf599a1924534` |

After placing the config files, generate the Dart options file using the [FlutterFire CLI](https://firebase.flutter.dev/docs/cli):

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart`. Then update `lib/main.dart` to use it:

```dart
import 'firebase_options.dart';

await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### 3. Generate code

Drift (database) and AutoRoute (routing) both require code generation. Run once after cloning, and again after any schema or route changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run

```bash
flutter run
```

---

## Architecture

```
lib/
├── main.dart                  # Entry point — Firebase init, ProviderScope
├── app.dart                   # FlixsyApp — MaterialApp.router, skin theming
├── core/
│   ├── channels/              # MethodChannel + EventChannel bridge to ConnectSDK
│   └── errors/                # Typed failure hierarchy (ConnectFailure)
├── data/
│   ├── database/              # Drift DB, tables, DAOs, generated files
│   ├── models/                # Plain Dart data models
│   └── repositories/          # Repository implementations
├── domain/
│   └── repositories/          # Repository interfaces (pure Dart)
├── features/
│   └── <feature>/
│       ├── providers/         # Riverpod providers
│       ├── screens/           # Screen widgets
│       └── widgets/           # Feature-scoped widgets
├── l10n/                      # ARB files (12 locales) + generated AppLocalizations
├── theming/
│   ├── remote_skin.dart       # RemoteSkin interface
│   ├── skin_registry.dart     # AppSkin enum + SkinConfig map
│   ├── skin_provider.dart     # activeSkinProvider, skinConfigProvider
│   ├── icons/                 # Icon packs for remote keys
│   └── skins/                 # campfire, cityscape, classic, cloud,
│                              # honkytonk, main, ocean, waterfall
├── analytics/
│   └── analytics_service.dart # Firebase Analytics wrapper
├── router/
│   ├── app_router.dart        # AutoRoute config
│   └── app_router.gr.dart     # Generated — do not edit
└── shared/
    ├── ads/                   # AdMob service + RemoteBannerAd widget
    ├── providers/             # App-wide Riverpod providers
    └── widgets/               # Shared widgets
```

**Dependency flow:** Widgets → Providers → Repositories → Database / Channels

---

## State Management

Riverpod without code generation. No `@riverpod` annotations. All providers are top-level constants using explicit constructors (`Provider`, `StreamProvider`, `AsyncNotifierProvider`, etc.).

---

## Skins

Each skin lives in `lib/theming/skins/<skin>/` and provides a `ThemeData` and a widget implementing `RemoteSkin`. The active skin is persisted to the Drift `preferences_table` and exposed via `activeSkinProvider`.

**Available skins:** `campfire`, `cityscape`, `classic`, `cloud`, `honkytonk`, `main`, `ocean`, `waterfall`.

**To add a new skin:**

1. Create `lib/theming/skins/<skin>/<skin>_theme.dart` — return a `ThemeData`
2. Create `lib/theming/skins/<skin>/<skin>_remote_skin.dart` — implement `RemoteSkin`
3. Add the new `AppSkin` enum value and its `SkinConfig` to `lib/theming/skin_registry.dart`

No changes to screens, providers, or routing needed.

---

## Custom Layouts

Users can create and edit their own remote layouts (`features/layout_editor/`, `features/layout_picker/`). Layouts follow a 3-axis model — key catalog, layout data, and skin — so a single layout renders correctly in every skin. See `docs/custom_layouts_design.md` for the design.

---

## Localization

12 locales: `en`, `es`, `fr`, `de`, `pt`, `ja`, `zh`, `hi`, `ar`, `ru`, `it`, `ko`. The UI language follows the device locale — there is no in-app language picker. Arabic renders RTL; the remote control surface stays LTR.

- Source of truth: `lib/l10n/app_en.arb` (keys + English text + `@key` descriptions).
- Other locales: `lib/l10n/app_<locale>.arb` — blank cells fall back to English.
- Generated: `lib/l10n/generated/` (do not edit, do not gitignore).
- Access in widgets via `context.l10n.<key>` (extension in `lib/core/extensions/l10n_extensions.dart`). No user-facing string literals in widgets.

**Translation round-trip** (ARB ↔ Google Sheets via CSV):

```bash
dart run tool/l10n_csv.dart export   # ARB  -> l10n_strings.csv
# ...translate locale columns in Sheets, download as CSV...
dart run tool/l10n_csv.dart import   # CSV  -> ARB
flutter gen-l10n                     # regenerate AppLocalizations
```

---

## ConnectSDK (Platform Channels)

ConnectSDK is a native library — not available as a Dart package.

| Side | Location |
|------|----------|
| Dart bridge | `lib/core/channels/connect_channel.dart` |
| Android handler | `android/app/src/main/kotlin/` |
| iOS handler | `ios/Runner/` |

Channel names: `com.flixsy.app/connect_sdk` (methods), `com.flixsy.app/connect_sdk_events` (events).

---

## Ads

Test ad unit IDs are active by default. Real IDs must be injected via environment config — never hardcode them in source. GDPR/UMP consent must be obtained before any ads are loaded.

---

## Analytics

All events go through `AnalyticsService` — never call `FirebaseAnalytics` directly. Events are logged from notifiers and repositories, not from widgets. Event name constants are defined in `AnalyticsService`.

---

## Testing

```bash
flutter test
```

- Mock `MethodChannel` using `TestDefaultBinaryMessengerBinding`
- Use `NativeDatabase.memory()` for in-memory Drift databases in tests
- Override providers with `ProviderScope(overrides: [...])` in widget tests
- Never call real Firebase or AdMob in tests
