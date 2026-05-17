import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The Flixsy brand mark, rendered from a vector asset so it stays crisp
/// at any size.
///
/// The underlying SVG is square; [size] sets both its width and height.
class FlixsyLogo extends StatelessWidget {
  const FlixsyLogo({super.key, this.size = 96});

  /// Path to the vector asset, registered under `flutter/assets` in
  /// `pubspec.yaml`.
  static const String _assetPath = 'assets/images/flixsy_logo.svg';

  /// Width and height of the (square) logo, in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      _assetPath,
      width: size,
      height: size,
      semanticsLabel: 'Flixsy logo',
    );
  }
}
