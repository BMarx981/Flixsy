import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_surface.dart';

/// Shows a modal bottom sheet whose surface is a glass panel — same visual
/// language as [GlassSurface] used by the editor screen.
///
/// The returned future resolves to whatever the sheet pops with (or `null`
/// if dismissed), matching [showModalBottomSheet].
Future<T?> showGlassModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    isScrollControlled: true,
    builder: (sheetContext) => _GlassSheetSurface(child: builder(sheetContext)),
  );
}

class _GlassSheetSurface extends StatelessWidget {
  const _GlassSheetSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    final borderRadius = const BorderRadius.vertical(
      top: Radius.circular(28),
    );
    return GlassSurface(
      borderRadius: borderRadius,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
