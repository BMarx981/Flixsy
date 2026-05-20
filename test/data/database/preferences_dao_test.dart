import 'package:drift/native.dart';
import 'package:flixsy/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('PreferencesDao — ads removed entitlement', () {
    test('getAdsRemoved defaults to false on a fresh database', () async {
      expect(await db.preferencesDao.getAdsRemoved(), isFalse);
    });

    test('setAdsRemoved(true) persists and is read back', () async {
      await db.preferencesDao.setAdsRemoved(true);
      expect(await db.preferencesDao.getAdsRemoved(), isTrue);
    });

    test('setAdsRemoved(false) overwrites a previous true', () async {
      await db.preferencesDao.setAdsRemoved(true);
      await db.preferencesDao.setAdsRemoved(false);
      expect(await db.preferencesDao.getAdsRemoved(), isFalse);
    });

    test('watchAdsRemoved emits the current value and subsequent changes', () {
      expectLater(
        db.preferencesDao.watchAdsRemoved(),
        emitsInOrder([false, true, false]),
      );

      Future(() async {
        await db.preferencesDao.setAdsRemoved(true);
        await db.preferencesDao.setAdsRemoved(false);
      });
    });
  });
}
