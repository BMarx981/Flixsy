import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/l10n_extensions.dart';
import '../../../data/models/layout/remote_layout.dart';
import '../../../theming/skin_provider.dart';
import '../../../theming/skin_registry.dart';

/// Swipe-to-pick carousel that the user enters from the home screen.
///
/// Each page renders a registered skin inside its own [Theme], so mid-swipe
/// the revealed page already looks correct even before the global theme
/// catches up. When the [PageView] settles, [previewSkinProvider] is updated
/// — that re-themes the rest of the app (app bar, chrome) live, without
/// persisting until the user taps Apply on the home screen.
///
/// Remote keys are intentionally inert during preview: the user is choosing a
/// look, not driving the TV, and a stray tap on a still-loading skin should
/// never reach the device.
class SkinPickerCarousel extends ConsumerStatefulWidget {
  const SkinPickerCarousel({
    super.key,
    required this.layout,
    required this.imagePaths,
  });

  final RemoteLayout layout;
  final Map<String, String> imagePaths;

  @override
  ConsumerState<SkinPickerCarousel> createState() =>
      _SkinPickerCarouselState();
}

class _SkinPickerCarouselState extends ConsumerState<SkinPickerCarousel> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    final preview = ref.read(previewSkinProvider);
    final initial = preview == null ? 0 : AppSkin.values.indexOf(preview);
    _controller = PageController(
      initialPage: initial < 0 ? 0 : initial,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _step(int delta) async {
    final current = _controller.page?.round() ?? 0;
    final next = (current + delta).clamp(0, AppSkin.values.length - 1);
    if (next == current) return;
    await _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final skins = AppSkin.values;
    final preview = ref.watch(previewSkinProvider) ?? skins.first;
    final currentIndex = skins.indexOf(preview);
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: currentIndex > 0 ? () => _step(-1) : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: l10n.skinPickerPreviousTooltip,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _skinLabel(preview),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < skins.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _Dot(
                          active: i == currentIndex,
                          color: colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed:
                  currentIndex < skins.length - 1 ? () => _step(1) : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: l10n.skinPickerNextTooltip,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: skins.length,
            onPageChanged: (i) =>
                ref.read(previewSkinProvider.notifier).state = skins[i],
            itemBuilder: (context, i) {
              final config = skinRegistry[skins[i]]!;
              return Theme(
                data: config.themeData,
                // Preview is look-only — block taps from driving the TV.
                child: IgnorePointer(
                  child: config.buildRemoteSkin(
                    layout: widget.layout,
                    imagePaths: widget.imagePaths,
                    onKeyPressed: (_) {},
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  static String _skinLabel(AppSkin skin) {
    final name = skin.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 18 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? color : color.withAlpha(80),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
