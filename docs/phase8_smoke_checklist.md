# Phase 8 — Manual smoke-test checklist

Verification pass for the pure-Dart remote channels (Roku + LG webOS + Samsung
Tizen + Google/Android TV behind `CompositeRemoteChannel`). Run this on a
**physical iOS and Android device** — emulators/simulators can't reach LAN TVs.

The four target TVs and the phone must all be on the **same Wi-Fi subnet**.
Guest networks and "client isolation" / AP-isolation settings break discovery.

## 0. Pre-flight

- [ ] `dart format .` — no diff.
- [ ] `flutter analyze` — zero warnings.
- [ ] Full test suite green (`flutter test`).
- [ ] Build a real device (not the FAKE_TV path): `flutter run --release` on a
      physical Android phone and a physical iPhone.

## 1. FAKE_TV path (no hardware needed)

`flutter run --dart-define=FAKE_TV=true`

- [ ] App launches; discovery lists the simulated TV(s).
- [ ] Connect succeeds; the remote screen renders.
- [ ] Each key on the remote produces a logged `key_sent` (check debug console).
- [ ] Switching skins keeps the same device connected and routing intact.
- [ ] Disconnect returns to the discovery screen cleanly.

## 2. Per-platform live tests

For **each** TV, repeat: discover → connect/pair → send keys → disconnect.

### Roku (SSDP `roku:ecp`, no pairing)
- [ ] Roku appears in discovery within a few seconds; name/model populated.
- [ ] Connect succeeds with no pairing prompt.
- [ ] D-pad (up/down/left/right/OK), Back, Home move the Roku UI.
- [ ] Volume / mute (Roku TV models), play/pause on a playing video.
- [ ] Disconnect; reconnect still works.

### LG webOS (SSDP `webos-second-screen`, confirm-on-TV pairing)
- [ ] LG TV appears in discovery.
- [ ] First connect → TV shows a pairing prompt; app shows the
      "Check your TV" banner (`confirmOnTv`).
- [ ] Accept on the TV → connection completes.
- [ ] D-pad, Back, Home, volume/mute, channel up/down all work
      (sent over the pointer-input socket).
- [ ] Disconnect, then reconnect → **no second pairing prompt**
      (client-key was persisted).

### Samsung Tizen (SSDP `RemoteControlReceiver`, token pairing)
- [ ] Samsung TV appears in discovery.
- [ ] First connect (2018+ model) → TV shows an allow/deny prompt; app shows
      the "Check your TV" banner.
- [ ] Allow on the TV → connection completes; token persisted.
- [ ] D-pad, Back, Home, volume/mute, channel up/down work (`KEY_*` codes).
- [ ] Disconnect, then reconnect → no second prompt (token reused).
- [ ] If a 2016–2017 model is available: connect succeeds via the
      `ws://8001` fallback with no prompt.

### Google / Android TV (mDNS `_androidtvremote2._tcp`, 6-digit code pairing)
- [ ] Android TV appears in discovery (mDNS — confirm the multicast lock is
      held on Android; see §3).
- [ ] First connect → TV displays a 6-digit code; app shows the code-entry
      field (`enterCode`).
- [ ] Enter the code → pairing completes, cert bundle persisted.
- [ ] D-pad, Back, Home, volume/mute, play/pause work (`KEYCODE_*`).
- [ ] Leave the remote idle ~20s → keepalive holds the connection
      (no unexpected disconnect before the 16s idle timeout fires on inject).
- [ ] Disconnect, then reconnect → no second code prompt (cert reused).

## 3. Platform plumbing (Phase 7)

### Android
- [ ] During discovery, logcat shows `MulticastLockPlugin: multicast lock
      acquired; held=true`.
- [ ] After `stopDiscovery`, logcat shows the matching `released; held=false`.
- [ ] Android TV (mDNS) is **not** discoverable with the lock removed —
      sanity check that the lock is actually doing work.
- [ ] Verified on Android 13/14 (`CHANGE_WIFI_MULTICAST_STATE` is a normal
      permission — no runtime prompt expected).

### iOS
- [ ] First discovery triggers the local-network permission prompt
      (`NSLocalNetworkUsageDescription` copy is correct).
- [ ] Android TV is discoverable on iOS (`_androidtvremote2._tcp` Bonjour
      service present).
- [ ] Roku/webOS/Samsung SSDP discovery works on iOS. **Note:** SSDP
      multicast needs the `com.apple.developer.networking.multicast`
      entitlement, which is created but **not yet wired** — until Apple
      grants it and `Runner.entitlements` is wired, SSDP discovery on iOS
      may be limited. Record actual behavior here.

## 4. Cross-cutting

- [ ] Composite routing: connect Roku, then connect a webOS TV — the Roku
      connection drops and keys route only to the webOS TV.
- [ ] Partial discovery failure (e.g. one TV powered off) does not break
      discovery of the others.
- [ ] Skin switching mid-session preserves the active connection.
- [ ] Banner ad renders on the relevant screens; no layout shift.
- [ ] Firebase Analytics receives `device_connected`, `device_disconnected`,
      `key_sent`, `skin_changed`, `ad_viewed` (DebugView).
- [ ] No raw `PlatformException` / `ConnectFailure` reaches the UI as an
      uncaught error — failures surface as in-app error states.

## Sign-off

| Platform     | Discover | Pair | Keys | Reconnect | Tester | Date |
|--------------|----------|------|------|-----------|--------|------|
| Roku         |          | n/a  |      |           |        |      |
| LG webOS     |          |      |      |           |        |      |
| Samsung      |          |      |      |           |        |      |
| Android TV   |          |      |      |           |        |      |
