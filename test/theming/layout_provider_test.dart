import 'package:drift/native.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flixsy/analytics/analytics_service.dart';
import 'package:flixsy/data/database/app_database.dart';
import 'package:flixsy/data/models/layout/built_in_layouts.dart';
import 'package:flixsy/data/models/layout/button_appearance.dart';
import 'package:flixsy/data/models/layout/layout_block.dart';
import 'package:flixsy/data/models/layout/remote_button.dart';
import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/data/models/stored_image.dart';
import 'package:flixsy/data/repositories/preferences_repository.dart';
import 'package:flixsy/domain/repositories/i_custom_image_repository.dart';
import 'package:flixsy/shared/providers/app_providers.dart';
import 'package:flixsy/theming/layout_provider.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late _FakeCustomImageRepository images;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    images = _FakeCustomImageRepository();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        analyticsServiceProvider.overrideWithValue(_NoopAnalytics()),
        customImageRepositoryProvider.overrideWithValue(images),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    return db.close();
  });

  group('LayoutController', () {
    test('selectLayout persists the chosen id', () async {
      await container.read(layoutControllerProvider).selectLayout('builtin:x');
      expect(await PreferencesRepository(db).getActiveLayoutId(), 'builtin:x');
    });

    test('updateLayout persists edits to a custom layout', () async {
      const custom = RemoteLayout(id: 'c1', name: 'Mine', blocks: []);
      await container.read(layoutRepositoryProvider).saveLayout(custom);

      await container
          .read(layoutControllerProvider)
          .updateLayout(
            const RemoteLayout(id: 'c1', name: 'Renamed', blocks: []),
          );

      final loaded = await container
          .read(layoutRepositoryProvider)
          .getLayout('c1');
      expect(loaded?.name, 'Renamed');
    });

    test('duplicateLayout saves an editable copy', () async {
      final copy = await container
          .read(layoutControllerProvider)
          .duplicateLayout(classicLayout);

      expect(copy.id, isNot(classicLayout.id));
      expect(copy.isTemplate, isFalse);
      expect(copy.name, 'Classic copy');
      expect(
        await container.read(layoutRepositoryProvider).getLayout(copy.id),
        isNotNull,
      );
    });

    test(
      'deleting the active layout falls back to the classic built-in',
      () async {
        const custom = RemoteLayout(id: 'c1', name: 'Mine', blocks: []);
        final controller = container.read(layoutControllerProvider);
        await container.read(layoutRepositoryProvider).saveLayout(custom);
        await controller.selectLayout('c1');
        expect(await PreferencesRepository(db).getActiveLayoutId(), 'c1');

        await controller.deleteLayout(custom);

        expect(
          await PreferencesRepository(db).getActiveLayoutId(),
          classicLayout.id,
        );
      },
    );

    test(
      'deleting a non-active layout leaves the active choice alone',
      () async {
        const custom = RemoteLayout(id: 'c1', name: 'Mine', blocks: []);
        final controller = container.read(layoutControllerProvider);
        await container.read(layoutRepositoryProvider).saveLayout(custom);
        await controller.selectLayout(classicLayout.id);

        await controller.deleteLayout(custom);

        expect(
          await PreferencesRepository(db).getActiveLayoutId(),
          classicLayout.id,
        );
      },
    );

    test(
      'updateLayout sweeps orphans, keeping the layout\'s own images',
      () async {
        const withImage = RemoteLayout(
          id: 'c1',
          name: 'Mine',
          blocks: [
            ButtonRowBlock(
              buttons: [
                RemoteButton(
                  action: RemoteKey.ok,
                  appearance: CustomImage(imageId: 'img-keep'),
                ),
              ],
            ),
          ],
        );
        await container.read(layoutRepositoryProvider).saveLayout(withImage);

        await container.read(layoutControllerProvider).updateLayout(withImage);

        // The save runs before the sweep, so the layout's image survives.
        expect(images.lastSweep, contains('img-keep'));
      },
    );

    test('deleteLayout runs the orphan sweep', () async {
      const custom = RemoteLayout(id: 'c1', name: 'Mine', blocks: []);
      final controller = container.read(layoutControllerProvider);
      await container.read(layoutRepositoryProvider).saveLayout(custom);

      await controller.deleteLayout(custom);

      expect(images.lastSweep, isNotNull);
    });
  });
}

/// Records the ids handed to the orphan sweep; performs no file work.
class _FakeCustomImageRepository implements ICustomImageRepository {
  Set<String>? lastSweep;

  @override
  Stream<List<StoredImage>> watchImages() =>
      const Stream<List<StoredImage>>.empty();

  @override
  Future<StoredImage?> importImage() async => null;

  @override
  Future<void> sweepOrphans(Set<String> referencedIds) async {
    lastSweep = referencedIds;
  }
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
