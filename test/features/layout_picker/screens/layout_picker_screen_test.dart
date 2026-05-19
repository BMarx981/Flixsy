import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flixsy/analytics/analytics_service.dart';
import 'package:flixsy/data/models/layout/built_in_layouts.dart';
import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/domain/repositories/i_layout_repository.dart';
import 'package:flixsy/domain/repositories/i_preferences_repository.dart';
import 'package:flixsy/features/layout_picker/screens/layout_picker_screen.dart';
import 'package:flixsy/shared/providers/app_providers.dart';
import 'package:flixsy/theming/skin_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeLayoutRepository layouts;
  late _FakePreferencesRepository preferences;

  setUp(() {
    layouts = _FakeLayoutRepository();
    preferences = _FakePreferencesRepository();
  });

  tearDown(() {
    layouts.dispose();
    preferences.dispose();
  });

  Future<void> pumpPicker(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          layoutRepositoryProvider.overrideWithValue(layouts),
          preferencesRepositoryProvider.overrideWithValue(preferences),
          analyticsServiceProvider.overrideWithValue(_NoopAnalytics()),
        ],
        child: const MaterialApp(home: LayoutPickerScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The overflow-menu button within the card titled [layoutName].
  Finder menuFor(String layoutName) => find.descendant(
    of: find.widgetWithText(Card, layoutName),
    matching: find.byIcon(Icons.more_vert),
  );

  testWidgets('lists the built-in Classic template', (tester) async {
    await pumpPicker(tester);

    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('Built-in template'), findsOneWidget);
  });

  testWidgets('shows custom layouts alongside the built-ins', (tester) async {
    layouts.seed(const RemoteLayout(id: 'mine', name: 'Den Remote', blocks: []));
    await pumpPicker(tester);

    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('Den Remote'), findsOneWidget);
  });

  testWidgets('tapping a layout makes it the active layout', (tester) async {
    layouts.seed(const RemoteLayout(id: 'mine', name: 'Den Remote', blocks: []));
    await pumpPicker(tester);

    await tester.tap(find.text('Den Remote'));
    await tester.pumpAndSettle();

    expect(preferences.activeLayoutId, 'mine');
  });

  testWidgets('duplicating a layout adds an editable copy', (tester) async {
    await pumpPicker(tester);

    await tester.tap(menuFor('Classic'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(find.text('Classic copy'), findsOneWidget);
  });

  testWidgets('built-in templates have no delete action', (tester) async {
    await pumpPicker(tester);

    await tester.tap(menuFor('Classic'));
    await tester.pumpAndSettle();

    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('deleting a custom layout removes it after confirmation', (
    tester,
  ) async {
    layouts.seed(const RemoteLayout(id: 'doomed', name: 'Doomed', blocks: []));
    await pumpPicker(tester);
    expect(find.text('Doomed'), findsOneWidget);

    await tester.tap(menuFor('Doomed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Confirm in the dialog.
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Doomed'), findsNothing);
  });

  testWidgets('cancelling the delete dialog keeps the layout', (tester) async {
    layouts.seed(const RemoteLayout(id: 'doomed', name: 'Doomed', blocks: []));
    await pumpPicker(tester);

    await tester.tap(menuFor('Doomed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Doomed'), findsOneWidget);
  });
}

/// In-memory [ILayoutRepository]. A single-subscription [StreamController]
/// buffers the current layout list until the screen subscribes, then pushes
/// every change.
class _FakeLayoutRepository implements ILayoutRepository {
  _FakeLayoutRepository() {
    _controller.add(_snapshot());
  }

  final List<RemoteLayout> _custom = [];
  final StreamController<List<RemoteLayout>> _controller =
      StreamController<List<RemoteLayout>>();

  List<RemoteLayout> _snapshot() => [...builtInLayouts, ..._custom];

  /// Adds a custom layout before the screen is pumped.
  void seed(RemoteLayout layout) {
    _custom.add(layout);
    _controller.add(_snapshot());
  }

  @override
  Stream<List<RemoteLayout>> watchAllLayouts() => _controller.stream;

  @override
  Future<RemoteLayout?> getLayout(String id) async {
    for (final layout in _snapshot()) {
      if (layout.id == id) return layout;
    }
    return null;
  }

  @override
  Future<void> saveLayout(RemoteLayout layout) async {
    _custom
      ..removeWhere((l) => l.id == layout.id)
      ..add(layout);
    _controller.add(_snapshot());
  }

  @override
  Future<void> deleteLayout(String id) async {
    _custom.removeWhere((l) => l.id == id);
    _controller.add(_snapshot());
  }

  void dispose() => _controller.close();
}

/// In-memory [IPreferencesRepository] — only the active-layout id matters to
/// the picker; the skin and credential members are unused here.
class _FakePreferencesRepository implements IPreferencesRepository {
  _FakePreferencesRepository() {
    _layoutController.add(_activeLayoutId);
  }

  String? _activeLayoutId;
  final StreamController<String?> _layoutController =
      StreamController<String?>();

  /// The most recently selected layout id, for assertions.
  String? get activeLayoutId => _activeLayoutId;

  @override
  Stream<String?> watchActiveLayoutId() => _layoutController.stream;

  @override
  Future<String?> getActiveLayoutId() async => _activeLayoutId;

  @override
  Future<void> setActiveLayoutId(String layoutId) async {
    _activeLayoutId = layoutId;
    _layoutController.add(layoutId);
  }

  @override
  Stream<AppSkin> watchActiveSkin() => Stream<AppSkin>.empty();
  @override
  Future<AppSkin> getActiveSkin() async => AppSkin.classic;
  @override
  Future<void> setActiveSkin(AppSkin skin) async {}
  @override
  Future<String?> getDeviceCredential(String deviceId) async => null;
  @override
  Future<void> setDeviceCredential(String deviceId, String credential) async {}

  void dispose() => _layoutController.close();
}

/// Discards every analytics call — Firebase is never reached in tests.
class _NoopAnalytics implements AnalyticsService {
  @override
  Future<void> logSkinChanged(String skinName) async {}
  @override
  Future<void> logDeviceConnected(String deviceModel) async {}
  @override
  Future<void> logDeviceDisconnected() async {}
  @override
  Future<void> logKeySent(String key) async {}
  @override
  Future<void> logAdViewed(String adUnitId) async {}
  @override
  Future<void> logLayoutSelected(String layoutId) async {}
  @override
  Future<void> logLayoutCreated(String layoutId) async {}
  @override
  Future<void> logLayoutDeleted(String layoutId) async {}
  @override
  FirebaseAnalyticsObserver get observer => throw UnimplementedError();
}
