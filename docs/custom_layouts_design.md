# Design — User-editable remote layouts & skins

Status: **proposed** · Owner: Brian Marx · Last updated: 2026-05-19

## 1. Goal

Let users **edit built-in remote layouts and create their own**, while the app
keeps shipping new visual skins. Today every skin is a hand-written widget that
conflates three things; this design separates them so both lists scale.

## 2. The three axes

A remote control is the product of three independent concerns. Today they are
fused inside each skin widget — that is the root problem.

| Axis | What it is | Authored by | Stored as |
|---|---|---|---|
| **Capability** | *Which* keys exist (`UP`, `HOME`, `FAST_FORWARD`…) | Us | `RemoteKey` enum (code) |
| **Layout** | *Which* keys are placed *where* | **Users** | Drift rows (JSON) |
| **Skin** | Visual style — shape, color, animation, `ThemeData` | Us (Dart) | Code |

Consequences of the split:

- A **standard skin** renders *any* layout — it only decides how things look.
- A **bespoke skin** (the logo star) hand-codes its own hit-testing; it is a
  fixed "style + layout" package and **cannot host an arbitrary user layout**.
  User-created layouts render only under standard skins.
- The skin × layout matrix is real and required, but needs no "engine": it
  falls out of layout-as-data + skin-as-renderer.

## 3. Core principle — action ≠ appearance

A button is two independent parts:

- **Action** — the `RemoteKey` it sends. Always present. The function.
- **Appearance** — how it looks. Never affects behaviour.

A "Patrick stop button" is `action: PLAY_PAUSE` + `appearance: PackIcon(...)`.
Because appearance can never change what a button *does*, no custom layout can
ever be a *broken* layout — the worst case is an ugly one.

## 4. Data model

All layout data is JSON-serializable (it must round-trip through Drift and an
editor). Models live in `lib/data/models/layout/`.

### 4.1 RemoteKey catalog

`lib/theming/remote_key.dart` — the single source of truth for key codes.
Replaces the magic strings currently duplicated across skins.

```dart
enum RemoteKey {
  up('UP', RemoteKeyRole.dpad),
  down('DOWN', RemoteKeyRole.dpad),
  left('LEFT', RemoteKeyRole.dpad),
  right('RIGHT', RemoteKeyRole.dpad),
  ok('OK', RemoteKeyRole.dpad),
  back('BACK', RemoteKeyRole.navigation),
  home('HOME', RemoteKeyRole.navigation),
  rewind('REWIND', RemoteKeyRole.transport),
  playPause('PLAY_PAUSE', RemoteKeyRole.transport),
  fastForward('FAST_FORWARD', RemoteKeyRole.transport),
  volumeUp('VOLUME_UP', RemoteKeyRole.volume),
  volumeDown('VOLUME_DOWN', RemoteKeyRole.volume),
  mute('MUTE', RemoteKeyRole.volume),
  power('POWER', RemoteKeyRole.system);
  // …extended as channels gain support.

  const RemoteKey(this.code, this.role);
  final String code;          // the wire string passed to RemoteChannel
  final RemoteKeyRole role;
}
```

`code` is the only thing sent to `RemoteChannel.sendKeyCommand`. The default
icon + label for a key are a *presentation* concern and live in the icon
catalog (§6), not here, so `RemoteKey` carries no Flutter import beyond the
enum itself.

### 4.2 Layout

```dart
class RemoteLayout {
  final String id;            // uuid; built-in templates use a reserved prefix
  final String name;
  final bool isTemplate;      // true = read-only built-in; edits duplicate it
  final List<LayoutBlock> blocks;
}
```

### 4.3 Blocks (the block / section editor model)

A layout is an **ordered list of blocks**. The user adds, removes, and reorders
blocks; each block type renders itself responsively, so a layout is always
valid at any screen size. `LayoutBlock` is a `sealed` class:

| Block | Holds | Notes |
|---|---|---|
| `DpadBlock` | 5 buttons (up/down/left/right/ok) | Cross arrangement, fixed shape |
| `ButtonRowBlock` | `List<RemoteButton>` | Evenly spaced row, 1–5 buttons |
| `VolumeBlock` | 3 buttons (−/mute/+) | Rocker arrangement |
| `GridBlock` | `columns`, `List<RemoteButton?>` | Null cell = empty slot |
| `SpacerBlock` | `height` | Visual breathing room |

Adding a block type later = one new sealed subclass + one renderer method per
standard skin. No change to the editor framework or storage.

### 4.4 Button

```dart
class RemoteButton {
  final RemoteKey action;             // what it sends — always present
  final ButtonAppearance appearance;  // how it looks
}

sealed class ButtonAppearance {
  final String? labelOverride;        // null = key default; '' = hide label
}
//  DefaultLook   — catalog default icon + label for the action
//  BuiltInIcon   — { iconId }           from our curated "Standard" pack
//  PackIcon      — { packId, iconId }   from a branded/partner pack
//  CustomImage   — { imageId }          a user-uploaded image
//  TextOnly      —                      label only, no glyph
```

Deserialization is **total**: an unknown `iconId`, `packId`, or missing
`imageId` degrades to `DefaultLook` rather than throwing. A layout from a newer
app version, or referencing a deleted image, still renders.

## 5. Rendering

```
StandardRemote (widget)
  └─ walks RemoteLayout.blocks
       └─ for each block, calls the active skin's SectionRenderer
            └─ skin draws the block chrome (shape, color, press feedback)
                 └─ ButtonAppearance resolves the glyph painted inside
```

- `SectionRenderer` — interface with one `build…` method per block type. A
  **standard skin** = a `SectionRenderer` + a `ThemeData`.
- A **bespoke skin** ignores all of the above and implements `RemoteSkin`
  directly (today's `MainRemoteSkin`).
- Both produce a `Widget` satisfying the existing `RemoteSkin` contract, so
  `HomeScreen` is unchanged.
- Per-skin design tokens (button radius, glow, press-scale, accent) ride on a
  `ThemeExtension` so renderers read them from `Theme.of(context)`.

## 6. Icons & images

### 6.1 Icon catalog & packs

- An **icon pack** is a named collection of named icons. Ship one built-in
  `Standard` pack (the usual suspects: play, pause, stop, ⏪, ⏩, ⌂, back,
  power…). *Implemented (Phase 5):* the `Standard` pack is backed by Material
  `IconData` — no bundled assets — so every icon resolves synchronously and
  type-safely. Partner packs (Phase 7) may still ship bundled image assets.
- The pack model is **entitlement-aware** from day one — each pack carries an
  `isUnlocked` check — so partner packs (e.g. a Nickelodeon pack with a
  SpongeBob play button) slot in later behind a paywall. Partner packs are
  bundled assets now; downloadable delivery is a later concern.
- Actual partnerships, licensing, and the monetization UI are **out of scope**
  here — only the pack abstraction and the gate hook are designed now.

### 6.2 Custom images

- Stored as **files** in the app documents dir (`remote_images/<uuid>.png`),
  not as Drift BLOBs. Drift stores only the id → filename mapping.
- On import: pick via `image_picker`, resize/re-encode to a capped dimension
  (≈256 px) to bound storage.
- **Lifecycle:** a `custom_images` table tracks each image; deleting a button
  or layout schedules an orphan sweep that removes unreferenced files.

## 7. Persistence (Drift)

New tables under `lib/data/database/tables/`:

| Table | Columns |
|---|---|
| `custom_layouts` | `id`, `name`, `blocks_json`, `created_at`, `updated_at` |
| `custom_images` | `id`, `file_name`, `created_at` |

- The whole block tree serializes to one `blocks_json` TEXT column — layouts
  are small; no need to normalize blocks into rows.
- The **active layout id** joins the active skin in the existing preferences
  table.
- Access only through a new `LayoutRepository` (DAOs stay behind repositories,
  per project rules). Migrations go in `lib/data/database/migrations/` and are
  tested.
- Built-in layouts are **not** rows — they are `const` data in code, flagged
  `isTemplate: true`. "Edit a template" copies it into a `custom_layouts` row.

## 8. Editor & UX

- **Layout picker** — lists built-in templates + the user's layouts. Actions:
  *Use*, *Duplicate*, *Edit* (user layouts only), *Delete*.
- **Block editor screen** — a reorderable list of blocks with a live preview:
  - add a block (bottom sheet of block types),
  - remove / drag-reorder blocks,
  - tap a button to set its **action** (`RemoteKey` picker) and **appearance**
    (icon picker: Standard / packs / Your Images + upload / None).
- **Validation** — a layout cannot be saved empty; every button must have an
  action; appearance always resolves (falls back to `DefaultLook`).
- New routes added under AutoRoute (`LayoutPickerRoute`, `LayoutEditorRoute`);
  `app_router.dart` regenerated.

## 9. Analytics

Add to `AnalyticsService` (snake_case, no PII):
`layout_created`, `layout_edited`, `layout_selected`, `layout_deleted`,
`custom_image_added`, `icon_pack_opened`.

## 10. Phased plan

Each phase is independently shippable and tested. Phases 1–2 are pure refactor
with no user-facing change; the editor cannot exist until everything beneath it
is solid.

| Phase | Delivers | User-visible |
|---|---|---|
| **1. Key catalog** | `RemoteKey` enum; both current skins refactored onto it | — |
| **2. Layout model + renderer** | Serializable model, `StandardRemote`, `SectionRenderer`; `Classic` rebuilt as a standard skin; built-in layouts as `const` data | — |
| **3. Persistence** | `custom_layouts` table, `LayoutRepository`, active-layout pref, layout picker | choose between layouts |
| **4. Editor** | Block editor — add/remove/reorder, assign actions | build a layout |
| **5. Icons & labels** | `Standard` icon pack + picker, text-only buttons, label overrides | reskin buttons |
| **6. Custom images** | Image import, storage, lifecycle sweep | use own images |
| **7. Icon packs** *(later)* | Pack abstraction + entitlement gate | branded/premium packs |

The bespoke logo skin (`MainRemoteSkin`) is untouched by every phase — it keeps
working as a fixed package throughout.

## 11. Open questions

- **Registry**: the `AppSkin` enum + central map becomes a merge hotspot as
  skins grow. Moving to string-id self-registering descriptors needs a Drift
  migration (active skin is persisted as the enum). Deferred — revisit when it
  hurts (~5+ skins).
- **Layout sharing**: export/import a layout as a code or file. Not in scope;
  the JSON model makes it cheap to add later.
- **Monetization**: how partner packs are priced/gated. Product decision,
  deferred to Phase 7.

## 12. Risks

- **Scope** — Phases 4–6 are a real feature, not a refactor. Ship 1–3 first and
  validate the layout picker before committing to the editor.
- **Image storage growth** — mitigated by import-time resize + the orphan sweep.
- **Forward compatibility** — total deserialization (§4.4) is mandatory so a
  layout never crashes a newer or older build.
