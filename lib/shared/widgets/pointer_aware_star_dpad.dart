import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:flixsy/features/home/providers/pointer_session_provider.dart';
import 'package:flixsy/shared/widgets/spinnable_star_dpad.dart';

/// [SpinnableStarDpad] plus a Magic Mouse toggle button that activates the
/// gyro-driven free cursor when the connected TV supports it.
///
/// All D-pad props pass through unchanged. The toggle:
///
///  * is enabled when the connected TV exposes a [PointerControl] (webOS),
///  * is disabled and visibly muted when no pointer-capable TV is connected,
///  * starts a [pointerSessionProvider] session on tap and ends it on a
///    second tap.
///
/// While a session is active, the centre OK tap is rerouted through the
/// session's `click()` (sends a webOS pointer click) — so the user can click
/// what the cursor is hovering over without dropping out of aim mode.
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
    final session = ref.read(pointerSessionProvider.notifier);
    final sessionActive = ref.watch(pointerSessionProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpinnableStarDpad(
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
        ),
        const SizedBox(height: 8),
        const MagicMouseToggleButton(),
      ],
    );
  }
}

/// Toggle button that starts/stops a [pointerSessionProvider] session.
///
/// Greyed out (with a strikethrough icon) when the connected TV does not
/// expose a [PointerControl]; tapping a disabled button does nothing and
/// shows the unsupported tooltip on long-press.
class MagicMouseToggleButton extends ConsumerWidget {
  const MagicMouseToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPointer = ref.watch(pointerControlProvider) != null;
    final sessionActive = ref.watch(pointerSessionProvider);
    final session = ref.read(pointerSessionProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final label = context.l10n.magicMouseLabel;
    final tooltip = hasPointer ? null : context.l10n.magicMouseUnsupportedTooltip;

    final foreground = !hasPointer
        ? scheme.onSurface.withValues(alpha: 0.38)
        : sessionActive
        ? scheme.onPrimary
        : scheme.onSurface;
    final background = !hasPointer
        ? scheme.surfaceContainerHighest
        : sessionActive
        ? scheme.primary
        : scheme.surfaceContainerHighest;

    final button = Material(
      color: background,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: hasPointer
            ? () => sessionActive ? session.stop() : session.start()
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MagicMouseIcon(enabled: hasPointer, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: hasPointer,
      toggled: sessionActive,
      label: label,
      child: tooltip != null
          ? Tooltip(message: tooltip, child: button)
          : button,
    );
  }
}

/// Mouse icon with a diagonal strike-through line when disabled.
class _MagicMouseIcon extends StatelessWidget {
  const _MagicMouseIcon({required this.enabled, required this.color});

  final bool enabled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.mouse_outlined, size: 18, color: color);
    if (enabled) return icon;
    return CustomPaint(
      foregroundPainter: _StrikethroughPainter(color: color),
      child: icon,
    );
  }
}

class _StrikethroughPainter extends CustomPainter {
  const _StrikethroughPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.85),
      Offset(size.width * 0.85, size.height * 0.15),
      paint,
    );
  }

  @override
  bool shouldRepaint(_StrikethroughPainter oldDelegate) =>
      oldDelegate.color != color;
}
