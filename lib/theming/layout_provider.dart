import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/layout/built_in_layouts.dart';
import '../data/models/layout/remote_layout.dart';
import '../shared/providers/app_providers.dart';

/// Every available layout — built-in templates plus the user's custom
/// layouts — streamed from the Drift-backed [LayoutRepository].
final allLayoutsProvider = StreamProvider<List<RemoteLayout>>((ref) {
  return ref.watch(layoutRepositoryProvider).watchAllLayouts();
});

/// The id of the active layout, defaulting to the classic built-in when the
/// user has never made a choice.
final activeLayoutIdProvider = StreamProvider<String>((ref) {
  final repo = ref.watch(preferencesRepositoryProvider);
  return repo.watchActiveLayoutId().map((id) => id ?? classicLayout.id);
});

/// The resolved active [RemoteLayout].
///
/// Falls back to the classic built-in while the streams load, or if the
/// stored layout no longer exists (e.g. it was deleted) — the remote always
/// has something valid to render.
final activeLayoutProvider = Provider<RemoteLayout>((ref) {
  final id = ref.watch(activeLayoutIdProvider).valueOrNull ?? classicLayout.id;
  final layouts = ref.watch(allLayoutsProvider).valueOrNull ?? builtInLayouts;
  for (final layout in layouts) {
    if (layout.id == id) return layout;
  }
  return classicLayout;
});

final _uuid = Uuid();

/// Persists the user's layout choices, recording each change for analytics.
///
/// Writing a preference updates the Drift-backed providers above, which
/// re-render the remote — callers do not refresh anything themselves.
class LayoutController {
  const LayoutController(this._ref);

  final Ref _ref;

  /// Makes [layoutId] the active layout.
  Future<void> selectLayout(String layoutId) async {
    await _ref.read(preferencesRepositoryProvider).setActiveLayoutId(layoutId);
    await _ref.read(analyticsServiceProvider).logLayoutSelected(layoutId);
  }

  /// Copies [source] into a new, editable custom layout and returns it.
  Future<RemoteLayout> duplicateLayout(RemoteLayout source) async {
    final copy = RemoteLayout(
      id: _uuid.v4(),
      name: '${source.name} copy',
      blocks: source.blocks,
    );
    await _ref.read(layoutRepositoryProvider).saveLayout(copy);
    await _ref.read(analyticsServiceProvider).logLayoutCreated(copy.id);
    return copy;
  }

  /// Deletes a custom layout. If it was the active layout, the classic
  /// built-in becomes active so the remote always has something to render.
  Future<void> deleteLayout(RemoteLayout layout) async {
    final preferences = _ref.read(preferencesRepositoryProvider);
    await _ref.read(layoutRepositoryProvider).deleteLayout(layout.id);
    if (await preferences.getActiveLayoutId() == layout.id) {
      await preferences.setActiveLayoutId(classicLayout.id);
    }
    await _ref.read(analyticsServiceProvider).logLayoutDeleted(layout.id);
  }
}

final layoutControllerProvider = Provider<LayoutController>(
  (ref) => LayoutController(ref),
);
