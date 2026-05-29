import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// One entry in a [GlassPopupMenu].
class GlassPopupMenuItem<T> {
  const GlassPopupMenuItem({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}

/// Drop-in replacement for [PopupMenuButton] that renders a glassmorphic
/// menu and grows its trigger icon on tap.
class GlassPopupMenu<T> extends StatefulWidget {
  const GlassPopupMenu({
    super.key,
    required this.items,
    required this.onSelected,
    this.icon = const Icon(Icons.more_vert),
    this.tooltip,
    this.menuWidth = 260,
    this.maxIconScale = 1.45,
  });

  final List<GlassPopupMenuItem<T>> items;
  final ValueChanged<T> onSelected;
  final Widget icon;
  final String? tooltip;
  final double menuWidth;
  final double maxIconScale;

  @override
  State<GlassPopupMenu<T>> createState() => _GlassPopupMenuState<T>();
}

class _GlassPopupMenuState<T> extends State<GlassPopupMenu<T>>
    with TickerProviderStateMixin {
  final LayerLink _link = LayerLink();

  late final AnimationController _iconController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    reverseDuration: const Duration(milliseconds: 180),
  );
  late final Animation<double> _iconScale =
      Tween<double>(begin: 1.0, end: widget.maxIconScale).animate(
    CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInCubic,
    ),
  );

  late final AnimationController _menuController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    reverseDuration: const Duration(milliseconds: 160),
  );

  OverlayEntry? _entry;

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    _iconController.dispose();
    _menuController.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_entry != null || widget.items.isEmpty) return;
    _iconController.forward();
    final items = widget.items;
    final menuWidth = widget.menuWidth;

    _entry = OverlayEntry(
      builder: (_) => _GlassPopupSurface<T>(
        link: _link,
        animation: _menuController,
        items: items,
        menuWidth: menuWidth,
        onSelect: (value) async {
          await _close();
          if (!mounted) return;
          widget.onSelected(value);
        },
        onDismiss: _close,
      ),
    );
    Overlay.of(context).insert(_entry!);
    await _menuController.forward();
  }

  Future<void> _close() async {
    if (_entry == null) return;
    _iconController.reverse();
    await _menuController.reverse();
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: IconButton(
        tooltip:
            widget.tooltip ?? MaterialLocalizations.of(context).showMenuTooltip,
        onPressed: widget.items.isEmpty ? null : _open,
        icon: ScaleTransition(
          scale: _iconScale,
          child: widget.icon,
        ),
      ),
    );
  }
}

class _GlassPopupSurface<T> extends StatelessWidget {
  const _GlassPopupSurface({
    required this.link,
    required this.animation,
    required this.items,
    required this.menuWidth,
    required this.onSelect,
    required this.onDismiss,
  });

  final LayerLink link;
  final Animation<double> animation;
  final List<GlassPopupMenuItem<T>> items;
  final double menuWidth;
  final ValueChanged<T> onSelect;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tintTop = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.55);
    final tintBottom = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.30);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.75);
    // CompositedTransformFollower needs concrete Alignment values, not
    // AlignmentGeometry — resolve the directional anchors against the
    // ambient text direction so RTL mirrors the popup to the start side.
    final direction = Directionality.of(context);
    final targetAnchor = AlignmentDirectional.bottomEnd.resolve(direction);
    final followerAnchor = AlignmentDirectional.topEnd.resolve(direction);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: link,
            showWhenUnlinked: false,
            targetAnchor: targetAnchor,
            followerAnchor: followerAnchor,
            offset: const Offset(0, 8),
            child: SizedBox(
              width: menuWidth,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final curved = Curves.easeOutCubic
                      .transform(animation.value.clamp(0.0, 1.0));
                  return Opacity(
                    opacity: curved,
                    child: Transform.scale(
                      alignment: AlignmentDirectional.topEnd,
                      scale: 0.85 + 0.15 * curved,
                      child: child,
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [tintTop, tintBottom],
                        ),
                        border: Border.all(color: borderColor, width: 1),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final item in items)
                            _GlassMenuItem(
                              icon: item.icon,
                              label: item.label,
                              onTap: () => onSelect(item.value),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassMenuItem extends StatelessWidget {
  const _GlassMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: foreground.withValues(alpha: 0.08),
        highlightColor: foreground.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: foreground.withValues(alpha: 0.85)),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
