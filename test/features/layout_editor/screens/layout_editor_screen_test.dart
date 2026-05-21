import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flixsy/analytics/analytics_service.dart';
import 'package:flixsy/data/models/layout/layout_block.dart';
import 'package:flixsy/data/models/layout/remote_button.dart';
import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/domain/repositories/i_layout_repository.dart';
import 'package:flixsy/features/layout_editor/screens/layout_editor_screen.dart';
import 'package:flixsy/l10n/generated/app_localizations.dart';
import 'package:flixsy/shared/providers/app_providers.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _dpadLayout = RemoteLayout(
  id: 'l1',
  name: 'My Layout',
  blocks: [
    DpadBlock(
      up: RemoteButton(action: RemoteKey.up),
      down: RemoteButton(action: RemoteKey.down),
      left: RemoteButton(action: RemoteKey.left),
      right: RemoteButton(action: RemoteKey.right),
      ok: RemoteButton(action: RemoteKey.ok),
      volumeUp: RemoteButton(action: RemoteKey.volumeUp),
      volumeDown: RemoteButton(action: RemoteKey.volumeDown),
      channelUp: RemoteButton(action: RemoteKey.channelUp),
      channelDown: RemoteButton(action: RemoteKey.channelDown),
    ),
  ],
);

const _rowLayout = RemoteLayout(
  id: 'r1',
  name: 'Row',
  blocks: [
    ButtonRowBlock(buttons: [RemoteButton(action: RemoteKey.home)]),
  ],
);

const _emptyLayout = RemoteLayout(id: 'e1', name: 'Empty', blocks: []);

void main() {
  late _FakeLayoutRepository repo;

  setUp(() => repo = _FakeLayoutRepository());

  Future<void> pumpEditor(WidgetTester tester, RemoteLayout layout) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          layoutRepositoryProvider.overrideWithValue(repo),
          analyticsServiceProvider.overrideWithValue(_NoopAnalytics()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LayoutEditorScreen(layout: layout),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the editor with the layout blocks', (tester) async {
    await pumpEditor(tester, _dpadLayout);

    expect(find.text('Edit layout'), findsOneWidget);
    expect(find.text('D-pad'), findsOneWidget);
    expect(find.text('Add block'), findsOneWidget);
  });

  testWidgets('adding a block via the sheet appends it', (tester) async {
    // The d-pad card shows nine button chips, so it pushes the new Spacer
    // card past the default 800x600 viewport — give the test a taller view
    // so ReorderableListView builds the appended tile.
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpEditor(tester, _dpadLayout);

    await tester.tap(find.text('Add block'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spacer'));
    await tester.pumpAndSettle();

    expect(find.text('Spacer'), findsOneWidget);
    expect(find.text('D-pad'), findsOneWidget);
  });

  testWidgets('removing a block drops it from the editor', (tester) async {
    await pumpEditor(tester, _dpadLayout);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('D-pad'), findsNothing);
  });

  testWidgets('editing a button reassigns its action', (tester) async {
    await pumpEditor(tester, _rowLayout);
    expect(find.widgetWithText(ActionChip, 'Home'), findsOneWidget);

    // Tapping the chip opens the button editor sheet.
    await tester.tap(find.widgetWithText(ActionChip, 'Home'));
    await tester.pumpAndSettle();
    expect(find.text('Edit button'), findsOneWidget);

    // The Action row opens the action picker.
    await tester.tap(find.widgetWithText(ListTile, 'Action'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Up'));
    await tester.pumpAndSettle();

    // Confirm the edit back in the button editor.
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ActionChip, 'Up'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Home'), findsNothing);
  });

  testWidgets('editing a button switches it to text-only', (tester) async {
    await pumpEditor(tester, _rowLayout);

    await tester.tap(find.widgetWithText(ActionChip, 'Home'));
    await tester.pumpAndSettle();

    // The Icon row opens the icon picker; choose "Text only".
    await tester.tap(find.widgetWithText(ListTile, 'Icon'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Text only'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // The chip now carries the text-only marker icon.
    expect(
      find.descendant(
        of: find.byType(ActionChip),
        matching: find.byIcon(Icons.text_fields),
      ),
      findsOneWidget,
    );
  });

  testWidgets('saving an empty layout shows a validation message', (
    tester,
  ) async {
    await pumpEditor(tester, _emptyLayout);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Add at least one block before saving.'), findsOneWidget);
    expect(repo.saved, isEmpty);
  });

  testWidgets('saving a valid layout persists it through the controller', (
    tester,
  ) async {
    await pumpEditor(tester, _dpadLayout);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.saved.single.id, 'l1');
    expect(find.text('Layout saved.'), findsOneWidget);
  });
}

/// In-memory [ILayoutRepository] that records every saved layout.
class _FakeLayoutRepository implements ILayoutRepository {
  final List<RemoteLayout> saved = [];

  @override
  Future<void> saveLayout(RemoteLayout layout) async => saved.add(layout);

  @override
  Stream<List<RemoteLayout>> watchAllLayouts() =>
      const Stream<List<RemoteLayout>>.empty();

  @override
  Future<RemoteLayout?> getLayout(String id) async => null;

  @override
  Future<void> deleteLayout(String id) async {}
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
  Future<void> logLayoutEdited(String layoutId) async {}
  @override
  Future<void> logLayoutDeleted(String layoutId) async {}
  @override
  Future<void> logCustomImageAdded(String imageId) async {}
  @override
  Future<void> logPurchaseRemoveAds() async {}
  @override
  Future<void> logRestoreRemoveAds() async {}
  @override
  Future<void> logConsentResolved({required bool canRequestAds}) async {}
  @override
  FirebaseAnalyticsObserver get observer => throw UnimplementedError();
}
