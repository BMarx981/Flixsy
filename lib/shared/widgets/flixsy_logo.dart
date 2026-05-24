import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flixsy/core/extensions/l10n_extensions.dart';

/// The Flixsy brand mark, rendered from a vector asset so it stays crisp
/// at any size.
///
/// The underlying SVG is square; [size] sets both its width and height.
class FlixsyLogo extends StatelessWidget {
  const FlixsyLogo({super.key, this.size = 96, this.discColor});

  /// Path to the vector asset, registered under `flutter/assets` in
  /// `pubspec.yaml`.
  static const String _assetPath = 'assets/images/flixsy_logo.svg';

  /// Width and height of the (square) logo, in logical pixels.
  final double size;

  /// Optional override for the central pink disc. When set, the SVG's
  /// `#FF3D8A` fill is remapped to this color at paint time so the wheel
  /// can pick up the active skin's accent.
  final Color? discColor;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _assetPath,
      width: size,
      height: size,
      semanticsLabel: context.l10n.logoSemanticLabel,
      colorMapper: discColor == null ? null : _DiscColorMapper(discColor!),
    );
  }
}

/// Remaps the SVG's hard-coded pink disc fill to a runtime color while
/// leaving the outer ring and star untouched.
class _DiscColorMapper extends ColorMapper {
  const _DiscColorMapper(this.discColor);

  static const Color _pink = Color(0xFFFF3D8A);
  final Color discColor;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) => color == _pink ? discColor : color;
}
