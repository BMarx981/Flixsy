import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Carries the custom-image id → file-path map down to standard renderers.
///
/// Renderers are skin widgets and never read Riverpod providers (project
/// rule), so [StandardRemote] wraps its subtree in this scope and a renderer
/// resolves a `CustomImage` button through [RemoteImageScope.of]. Whoever
/// builds the remote — `home_screen`, the editor preview — supplies the map.
class RemoteImageScope extends InheritedWidget {
  const RemoteImageScope({
    super.key,
    required this.imagePaths,
    required super.child,
  });

  /// Custom-image id → absolute file path. Empty while the images load.
  final Map<String, String> imagePaths;

  /// The image paths in scope at [context], or an empty map when there is no
  /// enclosing [RemoteImageScope].
  static Map<String, String> of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<RemoteImageScope>();
    return scope?.imagePaths ?? const {};
  }

  @override
  bool updateShouldNotify(RemoteImageScope oldWidget) =>
      !mapEquals(imagePaths, oldWidget.imagePaths);
}
