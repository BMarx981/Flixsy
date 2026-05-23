import 'package:flutter/material.dart';

/// Per-skin design tokens that standard `SectionRenderer`s read from
/// `Theme.of(context)`.
///
/// Each standard skin registers a [SkinTokens] on its [ThemeData.extensions];
/// renderers stay generic by reading tokens here instead of hard-coding
/// spacing or colours (see `docs/custom_layouts_design.md` §5). The token set
/// grows as standard skins need more knobs.
@immutable
class SkinTokens extends ThemeExtension<SkinTokens> {
  const SkinTokens({required this.buttonGap, required this.accent});

  /// Spacing, in logical pixels, between adjacent buttons within a block.
  final double buttonGap;

  /// The skin's brand/accent color. Reads directly from the skin's palette,
  /// not from `ColorScheme.fromSeed`'s tonal-palette `primary` — which
  /// flattens every seed into a similar mid-saturation pastel under
  /// `Brightness.dark`, making accent-driven elements look identical across
  /// skins. Components like the spinnable wheel read this so each skin's
  /// signature color actually comes through.
  final Color accent;

  /// Used when a skin's [ThemeData] omits a [SkinTokens] extension.
  static const SkinTokens fallback = SkinTokens(
    buttonGap: 8,
    accent: Color(0xFFFF3D8A),
  );

  /// Resolves the tokens for [context], falling back to [fallback].
  static SkinTokens of(BuildContext context) =>
      Theme.of(context).extension<SkinTokens>() ?? fallback;

  @override
  SkinTokens copyWith({double? buttonGap, Color? accent}) => SkinTokens(
    buttonGap: buttonGap ?? this.buttonGap,
    accent: accent ?? this.accent,
  );

  @override
  SkinTokens lerp(ThemeExtension<SkinTokens>? other, double t) {
    if (other is! SkinTokens) return this;
    return SkinTokens(
      buttonGap: buttonGap + (other.buttonGap - buttonGap) * t,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
    );
  }
}
