import 'package:flixsy/data/models/layout/remote_layout.dart';

/// Access to remote layouts — the built-in `const` templates plus the user's
/// stored custom layouts. The only entry point to layout persistence; DAOs
/// stay hidden behind this interface (design doc §7).
abstract interface class ILayoutRepository {
  /// Every available layout: the built-in templates followed by the user's
  /// custom layouts, most recently updated first.
  Stream<List<RemoteLayout>> watchAllLayouts();

  /// Resolves a layout by id — a built-in template or a stored custom
  /// layout. Returns `null` when no layout matches.
  Future<RemoteLayout?> getLayout(String id);

  /// Inserts a custom layout, or replaces the existing one with the same id.
  /// Built-in templates are `const` data and are never written here.
  Future<void> saveLayout(RemoteLayout layout);

  /// Deletes the custom layout with [id]. A built-in template id is a no-op.
  Future<void> deleteLayout(String id);
}
