import 'package:drift/native.dart';
import 'package:flixsy/data/database/app_database.dart';
import 'package:flixsy/data/models/layout/built_in_layouts.dart';
import 'package:flixsy/data/models/layout/layout_block.dart';
import 'package:flixsy/data/models/layout/remote_button.dart';
import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/data/repositories/layout_repository.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LayoutRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LayoutRepository(db);
  });

  tearDown(() => db.close());

  const sample = RemoteLayout(
    id: 'custom-1',
    name: 'My Layout',
    blocks: [
      ButtonRowBlock(buttons: [RemoteButton(action: RemoteKey.ok)]),
    ],
  );

  group('getLayout', () {
    test('resolves a built-in template by id', () async {
      final layout = await repo.getLayout(classicLayout.id);
      expect(layout?.name, 'Classic');
      expect(layout?.isTemplate, isTrue);
    });

    test('returns null for an unknown id', () async {
      expect(await repo.getLayout('builtin:ghost'), isNull);
      expect(await repo.getLayout('no-such-layout'), isNull);
    });
  });

  group('saveLayout / getLayout', () {
    test('round-trips a custom layout, block tree included', () async {
      await repo.saveLayout(sample);
      final loaded = await repo.getLayout('custom-1');

      expect(loaded, isNotNull);
      expect(loaded!.name, 'My Layout');
      expect(loaded.isTemplate, isFalse);
      final block = loaded.blocks.single as ButtonRowBlock;
      expect(block.buttons.single.action, RemoteKey.ok);
    });

    test('preserves createdAt when an existing layout is updated', () async {
      await repo.saveLayout(sample);
      final created = (await db.layoutsDao.getById('custom-1'))!.createdAt;

      await repo.saveLayout(
        const RemoteLayout(id: 'custom-1', name: 'Renamed', blocks: []),
      );
      final row = (await db.layoutsDao.getById('custom-1'))!;

      expect(row.name, 'Renamed');
      expect(row.createdAt, created);
    });

    test('a corrupt blocks_json degrades to an empty layout', () async {
      final now = DateTime.now();
      await db.layoutsDao.upsert(
        CustomLayoutsTableCompanion.insert(
          id: 'bad',
          name: 'Broken',
          blocksJson: '{not valid json',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final loaded = await repo.getLayout('bad');
      expect(loaded, isNotNull);
      expect(loaded!.name, 'Broken');
      expect(loaded.blocks, isEmpty);
    });
  });

  test('watchAllLayouts lists built-ins, then custom layouts', () async {
    await repo.saveLayout(sample);
    final all = await repo.watchAllLayouts().first;

    expect(all.first.id, classicLayout.id);
    expect(all.map((l) => l.id), contains('custom-1'));
    expect(all, hasLength(builtInLayouts.length + 1));
  });

  test('deleteLayout removes a custom layout', () async {
    await repo.saveLayout(sample);
    await repo.deleteLayout('custom-1');
    expect(await repo.getLayout('custom-1'), isNull);
  });
}
