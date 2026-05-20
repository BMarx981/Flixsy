# CLAUDE.md

## Project Overview

A Flutter TV remote control app for iOS and Android that communicates with TVs via the ConnectSDK native library, bridged through Flutter Platform Channels. State is managed with Riverpod (no code generation). Local persistence uses Drift (with code generation). Users can choose from multiple UI skins/themes that share the same routing and business logic. Firebase Analytics is used for event tracking. Google AdMob provides ads.

---

## Architecture

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── channels/          # Platform channel definitions and Dart-side bridges
│   ├── errors/            # Failure types, error handling
│   └── extensions/        # Dart extensions
├── data/
│   ├── database/          # Drift DB, DAOs, table definitions, generated files
│   ├── models/            # Data models (plain Dart classes)
│   └── repositories/      # Repository implementations
├── domain/
│   ├── entities/          # Domain entities
│   └── repositories/      # Repository interfaces (abstract classes)
├── features/
│   └── <feature>/
│       ├── providers/     # Riverpod providers for this feature
│       ├── widgets/       # Widgets scoped to this feature
│       └── screens/       # Screen-level widgets
├── theming/
│   ├── skins/             # One subfolder per skin (classic/, neon/, minimal/, etc.)
│   │   └── <skin>/
│   │       ├── <skin>_theme.dart        # ThemeData for this skin
│   │       └── <skin>_remote_skin.dart  # Skin-specific widget implementations
│   ├── skin_registry.dart   # Enum + map of all registered skins
│   └── skin_provider.dart   # Riverpod provider for active skin, persisted via Drift
├── analytics/
│   └── analytics_service.dart  # Firebase Analytics wrapper
├── router/
│   ├── app_router.dart          # @AutoRouterConfig class + generated AppRouter
│   ├── app_router.gr.dart       # Generated — do not edit
│   └── guards/                  # AutoRoute route guards
└── shared/
    ├── ads/               # AdMob widget wrappers and ad provider
    ├── providers/         # App-wide Riverpod providers
    └── widgets/           # Shared/reusable widgets

android/
├── app/src/main/kotlin/   # Kotlin MethodChannel handler, ConnectSDK integration
ios/
├── Runner/                # Swift MethodChannel handler, ConnectSDK integration
```

---

## State Management — Riverpod

- Use **Riverpod without code generation**. Do not use `@riverpod` annotations or `riverpod_generator`. Do not add `riverpod_generator` or `riverpod_annotation` to `pubspec.yaml`.
- Declare all providers as top-level constants using the explicit provider constructors: `Provider`, `StateNotifierProvider`, `AsyncNotifierProvider`, `StreamProvider`, `FutureProvider`, etc.
- Prefer `AsyncNotifier` and `Notifier` (the non-generated base classes) for complex state, placed in `features/<feature>/providers/`.
- Use `ref.watch` inside widgets and `ref.read` inside callbacks and notifier methods.
- Never call `ref.read` inside `build`.
- Keep providers in dedicated files, one provider (or closely related provider family) per file.
- Use `family` for parameterized providers. Use `autoDispose` when state should not survive widget disposal.
- Do not put business logic inside widgets; delegate to notifiers or repositories via providers.

---

## Local Database — Drift

- Drift **code generation is allowed and expected**. Run `dart run build_runner build --delete-conflicting-outputs` to regenerate after schema changes.
- Generated files (`*.g.dart`) are committed to source control.
- Define tables in `lib/data/database/tables/`. Each table is its own file.
- Define DAOs in `lib/data/database/daos/`. Each DAO corresponds to one domain area.
- The main `AppDatabase` class lives in `lib/data/database/app_database.dart`.
- Use Drift's type-safe query API. Avoid raw SQL except when a complex query genuinely requires it, and document why.
- Expose database access only through repositories — widgets and providers never reference DAOs directly.
- Schema migrations go in `lib/data/database/migrations/` and must be tested.

---

## ConnectSDK — Platform Channels

ConnectSDK is a native SDK (Objective-C/Swift on iOS, Java/Kotlin on Android). It is **not** available as a Dart/Flutter package. All communication goes through Flutter Platform Channels.

### Dart side (`lib/core/channels/`)

- Define a single `ConnectChannel` class that owns the `MethodChannel` instance.
- The channel name must match exactly on both platforms: `com.<yourorg>.<appname>/connect_sdk`.
- All public methods are `async` and return typed results or throw a typed `ConnectFailure`.
- Never expose raw `dynamic` return types from the channel class; map platform responses to typed Dart models immediately.
- Use a `StreamController` (or `EventChannel`) for events pushed from the native side (device discovery, connection state changes).

```dart
const _channel = MethodChannel('com.<yourorg>.<appname>/connect_sdk');
```

### Android side (`android/app/src/main/kotlin/`)

- Implement the channel handler in a dedicated `ConnectSdkPlugin.kt` (or similar) class, not inside `MainActivity`.
- Register the plugin from `MainActivity.configureFlutterEngine`.
- Handle all ConnectSDK callbacks on the main thread before responding via `result.success` / `result.error`.
- Use `result.error(code, message, details)` for all error paths — never swallow exceptions.

### iOS side (`ios/Runner/`)

- Implement the channel handler in a dedicated `ConnectSdkPlugin.swift` class.
- Register it from `AppDelegate.application(_:didFinishLaunchingWithOptions:)`.
- Ensure ConnectSDK delegate callbacks are dispatched to the main queue before calling `result`.
- Use `FlutterError` for error paths.

### Method naming convention

Use `camelCase` method names that match on both platforms:

| Action | Method name |
|---|---|
| Start device discovery | `startDiscovery` |
| Stop device discovery | `stopDiscovery` |
| Connect to device | `connectToDevice` |
| Disconnect | `disconnect` |
| Send key command | `sendKeyCommand` |
| Get device list | `getDiscoveredDevices` |

### Error handling

- Define a `ConnectFailure` sealed class (or enum-based hierarchy) in `lib/core/errors/`.
- Map platform error codes to `ConnectFailure` subtypes in `ConnectChannel`.
- Providers expose failures through `AsyncValue.error`; never let raw `PlatformException` propagate to the UI layer.

---

## Platform Channel Event Handling

For continuous native→Dart events (discovery results, connection state), prefer `EventChannel` over polling:

- Dart: `EventChannel('com.<yourorg>.<appname>/connect_sdk_events').receiveBroadcastStream()`
- Android: Implement `EventChannel.StreamHandler`
- iOS: Implement `FlutterStreamHandler`

Convert the broadcast stream into a Riverpod `StreamProvider` so the rest of the app reacts to it naturally.

---

## Routing — AutoRoute

AutoRoute **does** use code generation. The generated file `app_router.gr.dart` is committed to source control.

### Setup

- The `@AutoRouterConfig` class lives in `lib/router/app_router.dart`.
- `MaterialApp.router` in `app.dart` receives `appRouter.config()`.
- The `AppRouter` instance is provided app-wide via a `Provider<AppRouter>` in `shared/providers/`.
- Never instantiate `AppRouter` more than once — use the provider everywhere.

### Conventions

- Every screen that is a route destination must be annotated with `@RoutePage()`.
- Route names use `PascalCase` matching the screen class name: `HomeScreen` → `HomeRoute`.
- Nested navigation (e.g. tabs) uses `AutoTabsRouter`; declare child routes as `children` on the parent in `app_router.dart`.
- Pass route parameters as typed constructor arguments on the screen — never pass raw `Map` or `dynamic` through routes.
- Route guards go in `lib/router/guards/` and implement `AutoRouteGuard`.

### Code generation

Run after any change to `app_router.dart` or adding/removing `@RoutePage()` annotations:

```bash
dart run build_runner build --delete-conflicting-outputs
```

`app_router.gr.dart` is committed. Do not `.gitignore` it.

### Navigation

- Navigate using `context.router` (from the `auto_route` extension) or inject `AppRouter` via `ref.read(appRouterProvider)` in notifiers.
- Never use `Navigator.of(context)` directly — always go through AutoRoute.
- Attach a `FirebaseAnalyticsObserver` as a `NavigatorObserver` in `appRouter.config()` so screen transitions are tracked automatically.

---

## UI Skins & Theming

The app offers multiple visual skins. All skins share the same routes, screens, and business logic — only the visual presentation differs.

### How skins work

- Each skin lives in `lib/theming/skins/<skin>/` and provides two things:
  1. A `ThemeData` (e.g. `ClassicTheme.themeData`) applied at the `MaterialApp` level.
  2. A skin widget implementation conforming to a shared `RemoteSkin` abstract interface (e.g. `ClassicRemoteSkin`).
- `lib/theming/skin_registry.dart` contains the `AppSkin` enum and a `Map<AppSkin, SkinConfig>` that pairs each enum value with its `ThemeData` and widget factory.
- The active skin is stored in Drift (user preferences table) and loaded at startup.
- `lib/theming/skin_provider.dart` exposes two providers:
  - `activeSkinProvider` — a `StreamProvider<AppSkin>` backed by the Drift preference.
  - `skinConfigProvider` — a `Provider<SkinConfig>` derived from `activeSkinProvider`.

### Skin widget state

- Skin widgets (buttons, D-pads, sliders, etc.) may have their own ephemeral UI state (pressed animations, hover highlights, loading indicators).
- This state lives **inside the skin widget** using `StatefulWidget` or a scoped `autoDispose` provider — it must not leak into shared/app-level providers.
- Skin widgets receive all data and callbacks through constructor parameters. They do not call `ref.read` on business logic providers directly.
- When building new skin widgets, always implement the `RemoteSkin` interface — never build a skin-specific screen that diverges from the shared screen structure.

### Adding a new skin

1. Create `lib/theming/skins/<skin>/` with `<skin>_theme.dart` and `<skin>_remote_skin.dart`.
2. Implement `RemoteSkin` in the skin widget file.
3. Register the new `AppSkin` enum value and its `SkinConfig` in `skin_registry.dart`.
4. No changes to screens, providers, or routing are needed.

---

## Localization (i18n)

The app ships worldwide and is fully localized. The UI language follows the
**device locale automatically** — there is no in-app language picker.

### Toolchain

- Flutter's built-in `gen_l10n`. `flutter_localizations` (SDK) + `intl` are
  dependencies, and `generate: true` is set under `flutter:` in `pubspec.yaml`.
- Configuration lives in `l10n.yaml` (project root).
- `MaterialApp.router` in `app.dart` wires `AppLocalizations.localizationsDelegates`
  and `AppLocalizations.supportedLocales`; the OS window title uses
  `onGenerateTitle` so it is localized too.

### ARB files — source of truth

- Translations live in `lib/l10n/app_<locale>.arb`. **`app_en.arb` is the
  single source of truth** — it holds every key, the English text, and a
  `description` for each key (translator context). Edit it, never the others
  by hand.
- Generated localizations land in `lib/l10n/generated/` (the `AppLocalizations`
  class). They are produced by `flutter gen-l10n` and on build — do not edit
  them, and do not `.gitignore` them.
- Supported locales: `en`, `es`, `fr`, `de`, `pt`, `ja`, `zh`, `hi`, `ar`,
  `ru`, `it`, `ko`. A key missing from a non-English ARB falls back to English.

### Translation workflow (CSV ↔ spreadsheet)

`tool/l10n_csv.dart` round-trips the ARB files through one CSV so translators
can work in Google Sheets:

```bash
dart run tool/l10n_csv.dart export   # ARB  -> l10n_strings.csv
# ...translate the locale columns in Google Sheets, download as CSV...
dart run tool/l10n_csv.dart import   # l10n_strings.csv -> app_<locale>.arb
flutter gen-l10n                     # regenerate AppLocalizations
```

`export` always takes keys + English from `app_en.arb` and preserves existing
translations. `import` rewrites every non-English ARB; a blank cell is omitted
so that key falls back to English at runtime.

### Rules

- **No user-facing string literals in widgets.** Every visible string —
  including tooltips, hints, `SnackBar`/dialog text, and `semanticsLabel`s —
  comes from `AppLocalizations`, reached via `context.l10n` (the extension in
  `lib/core/extensions/l10n_extensions.dart`).
- To add a string: add the key + `@key` description to `app_en.arb`, run
  `flutter gen-l10n`, then use `context.l10n.<key>`. Use ICU `plural`/`select`
  and named placeholders for counts and interpolation — never concatenate or
  pluralize strings in Dart.
- Enum → string mappings are extensions on `AppLocalizations`: `RemoteKey`,
  `RemoteKeyRole`, and icon-pack ids in `theming/icons/remote_key_l10n.dart`;
  `ConnectFailure` in `l10n_extensions.dart`. Block-kind / appearance labels
  are switched inline in the feature widget that owns the enum.
- `ConnectFailure.message` stays English and technical — it is for logs only.
  The UI shows `context.l10n.failureMessage(failure)`, mapped from the failure
  *type*, so `core/` and `domain/` never depend on localization.

### Right-to-left (RTL)

- Arabic (`ar`) is supported; Material chrome (app bars, sheets, dialogs,
  list tiles) mirrors automatically.
- The **remote control surface is pinned to `TextDirection.ltr`** — a
  `Directionality` wrapper in `StandardRemote` and `MainRemoteSkin`. A D-pad's
  left/right and a grid's column order are physical geometry and must not
  mirror with the UI language; the button captions inside are still localized.
- Everywhere else, use direction-aware widgets (`EdgeInsetsDirectional`,
  `AlignmentDirectional`) — never hardcode `left`/`right`.

---

## Firebase Analytics

- All analytics calls go through `lib/analytics/analytics_service.dart`. Never call `FirebaseAnalytics` directly from widgets or providers.
- `AnalyticsService` is provided app-wide via a `Provider<AnalyticsService>` in `shared/providers/`.
- Use descriptive `snake_case` event names. Define event name constants inside `AnalyticsService` — no magic strings at call sites.
- Log events from notifiers or repositories, not from widgets. Widgets should not know about analytics.
- Standard events to track at minimum:

| Event | When |
|---|---|
| `skin_changed` | User selects a new skin |
| `device_connected` | ConnectSDK successfully connects to a TV |
| `device_disconnected` | Connection dropped or user disconnects |
| `key_sent` | A remote key command is sent |
| `ad_viewed` | An ad impression is recorded |

- Do not log personally identifiable information. Do not log device IP addresses or TV identifiers in plain form.

---

## Ads — Google AdMob

- Ad widget wrappers live in `lib/shared/ads/`. Never instantiate `BannerAd`, `InterstitialAd`, etc. directly in feature widgets.
- Provide a `AdService` class in `lib/shared/ads/ad_service.dart` that owns ad lifecycle (load, show, dispose). Expose it via a `Provider<AdService>`.
- Use test ad unit IDs during development. Real ad unit IDs are injected via environment/config — never hardcoded in source.
- Banner ads are wrapped in a `RemoteBannerAd` widget in `lib/shared/ads/`. Screens include this widget in their layout; skins do not control ad placement.
- Interstitial and rewarded ads are triggered from notifiers via `AdService`, not from widgets.
- Always dispose ads when the associated widget or notifier is disposed.
- Log an `ad_viewed` analytics event (via `AnalyticsService`) when an impression is recorded — do this in `AdService`, not in widgets.
- GDPR/consent handling must be implemented using the UMP SDK before any ads are loaded. Initialize consent before `AdService` loads any ads.

---

## pubspec.yaml — Key Dependencies

```yaml
dependencies:
  flutter_localizations:   # localization — see "Localization (i18n)"
    sdk: flutter
  intl: any
  flutter_riverpod: ^2.x.x
  drift: ^2.x.x
  sqlite3_flutter_libs: ^0.x.x
  path_provider: ^2.x.x
  path: ^1.x.x
  auto_route: ^9.x.x
  firebase_core: ^3.x.x
  firebase_analytics: ^11.x.x
  google_mobile_ads: ^5.x.x

dev_dependencies:
  build_runner: ^2.x.x
  drift_dev: ^2.x.x
  auto_route_generator: ^9.x.x
  csv: ^6.x.x              # ARB <-> CSV translation round-trip (tool/l10n_csv.dart)
  flutter_test:
    sdk: flutter
```

Do **not** add `riverpod_generator`, `riverpod_annotation`, or `freezed` unless explicitly decided as a team.

---

## Code Style & Conventions

- Dart SDK: follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style).
- Format all files with `dart format .` before committing.
- Analyze with `flutter analyze` — zero warnings policy; fix, don't suppress.
- No `dynamic` types except at the platform channel boundary, and only there.
- No `BuildContext` across async gaps — check `mounted` or use `ref`-based navigation.
- Prefer `const` constructors wherever possible.
- Prefer named parameters for functions with more than one parameter.
- Widget files contain one primary public widget. Helper widgets in the same file are private (`_`).

---

## Dependency Rules

- Widgets depend on providers. Providers depend on repositories. Repositories depend on the database or channel layer.
- The `domain/` layer has **no Flutter imports** — only pure Dart.
- `core/channels/` has no knowledge of Riverpod. It is a plain Dart service.
- Features do not import from other features directly — share through `shared/providers/` if needed.
- Skin widgets in `theming/` do not import from `analytics/` or `shared/ads/` — ad placement and analytics are the responsibility of screens and notifiers.
- `AnalyticsService` and `AdService` are never imported directly in widgets — always accessed via their providers.

---

## Code Generation

Both Drift and AutoRoute use code generation. Run the same command for both:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Run this after any change to:
- Drift table definitions, DAO classes, or `AppDatabase`
- `app_router.dart` or any `@RoutePage()` annotation

Generated files are committed. Do not `.gitignore` `*.g.dart` or `*.gr.dart` files inside `lib/data/database/` or `lib/router/`.

---

## Testing

- Unit test repositories, notifiers, and channel bridge logic.
- Mock the `MethodChannel` in tests using `TestDefaultBinaryMessengerBinding`.
- Mock the `AppDatabase` using an in-memory Drift database (`NativeDatabase.memory()`).
- Widget tests use `ProviderScope` with overridden providers — never rely on real platform channels in widget tests.
- Mock `AnalyticsService` and `AdService` in all widget and unit tests — never call Firebase or AdMob in tests.
- Skin widget tests should test each skin implementation against the `RemoteSkin` interface contract.
- Place tests mirroring the `lib/` structure under `test/`.

---

## Native Development Notes

- The ConnectSDK license and native SDK files live in `android/app/libs/` and `ios/Runner/ConnectSDK/` respectively.
- Do not attempt to wrap ConnectSDK in a Flutter plugin package — the channel implementation lives directly in the host app.
- iOS: add required `NSLocalNetworkUsageDescription` and Bonjour service entries to `Info.plist`.
- Android: add `CHANGE_WIFI_MULTICAST_STATE`, `ACCESS_WIFI_STATE`, and `INTERNET` permissions to `AndroidManifest.xml`.
- Multicast lock must be acquired/released on Android around discovery — do this in the Kotlin channel handler.