import 'package:flutter/widgets.dart';

/// Contract that every skin widget must satisfy.
/// Skin widgets are plain Flutter widgets that also expose their
/// callback interface so [SkinConfig] can construct them uniformly.
abstract interface class RemoteSkin {
  void Function(String key) get onKeyPressed;
}

/// Convenience typedef for the factory function stored in [SkinConfig].
typedef RemoteSkinBuilder = Widget Function({
  required void Function(String key) onKeyPressed,
});
