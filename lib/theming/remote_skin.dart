import 'package:flutter/widgets.dart';

import '../data/models/layout/remote_layout.dart';

/// Contract that every skin widget must satisfy.
/// Skin widgets are plain Flutter widgets that also expose their
/// callback interface so [SkinConfig] can construct them uniformly.
abstract interface class RemoteSkin {
  void Function(String key) get onKeyPressed;
}

/// Convenience typedef for the factory function stored in [SkinConfig].
///
/// [layout] is the active [RemoteLayout]. Standard skins render it; bespoke
/// skins (which hard-code their own arrangement) ignore it.
typedef RemoteSkinBuilder =
    Widget Function({
      required void Function(String key) onKeyPressed,
      required RemoteLayout layout,
    });
