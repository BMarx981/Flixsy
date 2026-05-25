import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flixsy/data/models/tv_device.dart';
import 'package:flixsy/features/device_discovery/providers/device_discovery_provider.dart';
import 'package:flixsy/shared/providers/active_device_provider.dart';
import 'package:flixsy/shared/providers/app_providers.dart';

/// Streams the user's nickname map. Empty map until the user has renamed at
/// least one device. Exposed at this layer (not [PreferencesRepository]
/// callers directly) so widgets keep one consistent stream lifetime.
final deviceNicknamesProvider = StreamProvider<Map<String, String>>((ref) {
  return ref.watch(preferencesRepositoryProvider).watchDeviceNicknames();
});

/// Resolves discovered devices to user-visible display names.
///
/// Resolution order per device:
///   1. user nickname, if set
///   2. discovery name
///
/// When two devices end up with the same display name (e.g. two "Living Room
/// TV"s on the network, or two devices renamed identically), the duplicates
/// are suffixed with " (2)", " (3)", … so the user can tell them apart on the
/// radar. Devices are sorted by id before numbering, which keeps suffixes
/// stable across discovery events within a session.
final deviceDisplayNamesProvider = Provider<Map<String, String>>((ref) {
  final devices = ref.watch(
    deviceDiscoveryProvider.select((s) => s.devices),
  );
  final nicknames = ref.watch(deviceNicknamesProvider).valueOrNull ?? const {};
  // Also include the currently-active device — it may not be in the radar's
  // device list anymore (e.g. between rebuilds) but the home AppBar still
  // needs to show its display name.
  final active = ref.watch(activeDeviceProvider);

  final all = <TvDevice>[
    ...devices,
    if (active != null && devices.every((d) => d.id != active.id)) active,
  ];
  return _resolveDisplayNames(all, nicknames);
});

/// Pure function — exposed for unit tests. Lives next to the provider so it
/// stays in sync with the resolution rule.
Map<String, String> resolveDisplayNamesForTesting(
  List<TvDevice> devices,
  Map<String, String> nicknames,
) =>
    _resolveDisplayNames(devices, nicknames);

Map<String, String> _resolveDisplayNames(
  List<TvDevice> devices,
  Map<String, String> nicknames,
) {
  if (devices.isEmpty) return const {};

  // Sort by id so the (2)/(3)/… ordering is stable across rebuilds.
  final ordered = [...devices]..sort((a, b) => a.id.compareTo(b.id));

  // First pass: base name per device.
  final baseNames = <String, String>{
    for (final d in ordered) d.id: nicknames[d.id] ?? d.name,
  };

  // Group by base name to find collisions.
  final groups = <String, List<String>>{};
  for (final d in ordered) {
    groups.putIfAbsent(baseNames[d.id]!, () => []).add(d.id);
  }

  final result = <String, String>{};
  for (final entry in groups.entries) {
    final ids = entry.value;
    if (ids.length == 1) {
      result[ids.first] = entry.key;
    } else {
      // First keeps the bare name; the rest get (2), (3), …
      for (var i = 0; i < ids.length; i++) {
        result[ids[i]] = i == 0 ? entry.key : '${entry.key} (${i + 1})';
      }
    }
  }
  return result;
}
