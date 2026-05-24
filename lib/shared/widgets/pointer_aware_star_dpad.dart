import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flixsy/features/home/providers/pointer_session_provider.dart';
import 'package:flixsy/shared/widgets/spinnable_star_dpad.dart';

/// [SpinnableStarDpad] wrapper that wires the long-press-OK gesture to the
/// app-wide [pointerSessionProvider] when the connected TV supports a free
/// cursor (currently only LG webOS).
///
/// All other props pass through unchanged. When the connected channel has no
/// [PointerControl], the long-press callbacks are null and the widget
/// behaves exactly like the bare [SpinnableStarDpad].
///
/// While a pointer session is active an OK tap is rerouted through the
/// session's `click()` (which calls `sendPointerClick` on webOS) instead of
/// firing the [onOk] callback — a pointer click activates whatever the
/// cursor is hovering over, which is what the user means by tapping while
/// aiming.
class PointerAwareStarDpad extends ConsumerWidget {
  const PointerAwareStarDpad({
    super.key,
    required this.size,
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
    required this.onOk,
    required this.onScrollUp,
    required this.onScrollDown,
    required this.onScrollLeft,
    required this.onScrollRight,
  });

  final double size;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onOk;
  final VoidCallback onScrollUp;
  final VoidCallback onScrollDown;
  final VoidCallback onScrollLeft;
  final VoidCallback onScrollRight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPointer = ref.watch(pointerControlProvider) != null;
    final session = ref.read(pointerSessionProvider.notifier);
    final sessionActive = ref.watch(pointerSessionProvider);

    return SpinnableStarDpad(
      size: size,
      onUp: onUp,
      onDown: onDown,
      onLeft: onLeft,
      onRight: onRight,
      onOk: sessionActive ? session.click : onOk,
      onScrollUp: onScrollUp,
      onScrollDown: onScrollDown,
      onScrollLeft: onScrollLeft,
      onScrollRight: onScrollRight,
      onOkLongPress: hasPointer ? session.start : null,
      onOkLongPressEnd: hasPointer ? session.stop : null,
    );
  }
}
