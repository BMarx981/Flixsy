import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:flixsy/data/models/tv_device.dart';
import 'package:flixsy/shared/providers/active_device_provider.dart';
import 'package:flixsy/theming/skin_provider.dart';
import 'package:flixsy/theming/skin_registry.dart';

/// Side-effect-only subscriber that converts state transitions in the active
/// skin and the active device into screen-reader live-region announcements.
///
/// Mounted as the [MaterialApp.router] `builder` wrapper so it lives inside
/// the Localizations + Directionality scopes the announcements need, but
/// above the routed content so it survives navigation. The announce calls
/// belong here — not in the buttons that trigger the change — because the
/// trigger is the state flip itself, not the gesture that caused it.
class StateAnnouncer extends ConsumerWidget {
  const StateAnnouncer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final view = View.of(context);
    final direction = Directionality.of(context);

    ref.listen<AsyncValue<AppSkin>>(activeSkinProvider, (prev, next) {
      final prevSkin = prev?.valueOrNull;
      final nextSkin = next.valueOrNull;
      if (prevSkin == null || nextSkin == null || prevSkin == nextSkin) return;
      SemanticsService.sendAnnouncement(
        view,
        l10n.accessibilitySkinChangedAnnouncement(_skinLabel(nextSkin)),
        direction,
      );
    });

    ref.listen<TvDevice?>(activeDeviceProvider, (prev, next) {
      if (prev == null && next != null) {
        SemanticsService.sendAnnouncement(
          view,
          l10n.accessibilityDeviceConnectedAnnouncement(next.name),
          direction,
        );
      } else if (prev != null && next == null) {
        SemanticsService.sendAnnouncement(
          view,
          l10n.accessibilityDeviceDisconnectedAnnouncement,
          direction,
        );
      }
    });

    return child;
  }

  // Skin enum names are stable identifiers, not user-facing copy; capitalising
  // the first letter mirrors the picker carousel's label so screen-reader
  // users hear the same name they'd see on screen.
  static String _skinLabel(AppSkin skin) {
    final name = skin.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
}
