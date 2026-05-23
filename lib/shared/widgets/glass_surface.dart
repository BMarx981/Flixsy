import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A reusable backdrop-blurred translucent surface, used to give panels,
/// cards, chips, and sheets a glassmorphic look. Matches the style of
/// [GlassPopupMenu] so the whole edit experience reads as one material.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding,
    this.blurSigma = 24,
    this.border = true,
    this.shadow = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final bool border;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tintTop = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.55);
    final tintBottom = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.30);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.75);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ]
            : const [],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tintTop, tintBottom],
              ),
              border: border
                  ? Border.all(color: borderColor, width: 1)
                  : null,
              borderRadius: borderRadius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A soft, full-bleed gradient backdrop so blurred glass surfaces have
/// something colorful to refract. Used behind the editor screen body and
/// behind the bottom sheets that open from it.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              colors.primary.withValues(alpha: 0.35),
              colors.surface,
            ),
            colors.surface,
            Color.alphaBlend(
              colors.secondary.withValues(alpha: 0.30),
              colors.surface,
            ),
          ],
        ),
      ),
      child: child,
    );
  }
}
