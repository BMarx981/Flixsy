import 'package:drift/native.dart';
import 'package:flixsy/data/database/app_database.dart';
import 'package:flixsy/data/database/migrations/app_migrations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDatabase migrations', () {
    test('schema version is 3', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, 3);
    });

    test('a fresh database has a usable custom_layouts table', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final now = DateTime.now();
      await db.layoutsDao.upsert(
        CustomLayoutsTableCompanion.insert(
          id: 'l1',
          name: 'Fresh',
          blocksJson: '[]',
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(await db.layoutsDao.getAll(), hasLength(1));
    });

    test('a fresh database has a usable custom_images table', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await db.customImagesDao.insertImage(
        CustomImagesTableCompanion.insert(
          id: 'img1',
          fileName: 'img1.png',
          createdAt: DateTime.now(),
        ),
      );

      expect(await db.customImagesDao.getAll(), hasLength(1));
    });

    test('the v1 → v2 upgrade adds custom_layouts and keeps preferences', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      // Seed a preference, then simulate a v1 database — one that predates
      // custom_layouts — by dropping the table.
      await db.preferencesDao.setActiveSkin('main');
      await db.customStatement(
        'DROP TABLE "${db.customLayoutsTable.actualTableName}"',
      );

      // Run the real v1 → v2 upgrade step.
      final strategy = createMigrationStrategy(db);
      await strategy.onUpgrade(db.createMigrator(), 1, 2);

      // The table is back and the pre-existing preference survived.
      expect(await db.layoutsDao.getAll(), isEmpty);
      expect(await db.preferencesDao.getActiveSkin(), 'main');

      final now = DateTime.now();
      await db.layoutsDao.upsert(
        CustomLayoutsTableCompanion.insert(
          id: 'l1',
          name: 'Migrated',
          blocksJson: '[]',
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect(await db.layoutsDao.getAll(), hasLength(1));
    });

    test('the v2 → v3 upgrade adds custom_images and keeps custom_layouts', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      // Seed a layout, then simulate a v2 database — one that predates
      // custom_images — by dropping the table.
      final now = DateTime.now();
      await db.layoutsDao.upsert(
        CustomLayoutsTableCompanion.insert(
          id: 'l1',
          name: 'Kept',
          blocksJson: '[]',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await db.customStatement(
        'DROP TABLE "${db.customImagesTable.actualTableName}"',
      );

      // Run the real v2 → v3 upgrade step.
      final strategy = createMigrationStrategy(db);
      await strategy.onUpgrade(db.createMigrator(), 2, 3);

      // The new table is usable and the pre-existing layout survived.
      expect(await db.customImagesDao.getAll(), isEmpty);
      expect(await db.layoutsDao.getAll(), hasLength(1));

      await db.customImagesDao.insertImage(
        CustomImagesTableCompanion.insert(
          id: 'img1',
          fileName: 'img1.png',
          createdAt: now,
        ),
      );
      expect(await db.customImagesDao.getAll(), hasLength(1));
    });
  });
}
