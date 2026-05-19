import 'package:flutter/widgets.dart';

/// One named icon within an [IconPack].
///
/// [id] is the stable wire value stored in a layout (`BuiltInIcon.iconId` /
/// `PackIcon.iconId`); [icon] and [name] are presentation only.
@immutable
class IconPackEntry {
  const IconPackEntry({
    required this.id,
    required this.name,
    required this.icon,
  });

  /// Stable identifier persisted in layout JSON. Never change an existing id.
  final String id;

  /// Human-readable name shown in the icon picker.
  final String name;

  /// The glyph this entry paints.
  final IconData icon;
}

/// A named collection of named icons (see `docs/custom_layouts_design.md` §6.1).
///
/// The pack model is **entitlement-aware** from day one: [isUnlocked] is the
/// gate hook for branded/partner packs that arrive behind a paywall in Phase 7.
/// The built-in `Standard` pack is always unlocked.
class IconPack {
  IconPack({
    required this.id,
    required this.name,
    required this.entries,
    this.isUnlocked = true,
  }) : _byId = {for (final entry in entries) entry.id: entry};

  /// Stable pack identifier persisted in layout JSON (`PackIcon.packId`).
  final String id;

  /// Human-readable pack name shown in the icon picker.
  final String name;

  /// Every icon in the pack, in display order.
  final List<IconPackEntry> entries;

  /// Whether the current user may use this pack. `true` for the `Standard`
  /// pack; partner packs (Phase 7) gate behind an entitlement check here.
  final bool isUnlocked;

  final Map<String, IconPackEntry> _byId;

  /// The entry with [iconId], or `null` when this pack has no such icon.
  ///
  /// Returning `null` rather than throwing keeps appearance resolution total:
  /// an unknown id degrades to the action's default icon, never a crash.
  IconPackEntry? resolve(String iconId) => _byId[iconId];
}
