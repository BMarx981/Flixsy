import 'dart:async';

import 'package:drift/native.dart';
import 'package:flixsy/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  group('DeviceNamesDao', () {
    test('getAll is empty on a fresh database', () async {
      expect(await db.deviceNamesDao.getAll(), isEmpty);
    });

    test('setNickname persists and is read back', () async {
      await db.deviceNamesDao.setNickname('id-1', 'Bedroom');
      expect(await db.deviceNamesDao.getAll(), {'id-1': 'Bedroom'});
    });

    test('setNickname overwrites a previous nickname', () async {
      await db.deviceNamesDao.setNickname('id-1', 'Bedroom');
      await db.deviceNamesDao.setNickname('id-1', 'Office');
      expect(await db.deviceNamesDao.getAll(), {'id-1': 'Office'});
    });

    test('clearNickname removes a single device only', () async {
      await db.deviceNamesDao.setNickname('id-1', 'Bedroom');
      await db.deviceNamesDao.setNickname('id-2', 'Living Room');
      await db.deviceNamesDao.clearNickname('id-1');
      expect(await db.deviceNamesDao.getAll(), {'id-2': 'Living Room'});
    });

    test(
        'watchAll re-emits whenever the table changes (final state reflects all writes)',
        () async {
      // Drift coalesces multiple writes that land in one microtask, so we
      // only assert that the stream eventually reaches each intermediate
      // state by awaiting between writes.
      final stream = db.deviceNamesDao.watchAll();
      final queue = StreamIterator(stream);

      expect(await queue.moveNext(), isTrue);
      expect(queue.current, isEmpty);

      await db.deviceNamesDao.setNickname('id-1', 'Bedroom');
      expect(await queue.moveNext(), isTrue);
      expect(queue.current, {'id-1': 'Bedroom'});

      await db.deviceNamesDao.setNickname('id-2', 'Living Room');
      expect(await queue.moveNext(), isTrue);
      expect(queue.current, {'id-1': 'Bedroom', 'id-2': 'Living Room'});

      await db.deviceNamesDao.clearNickname('id-1');
      expect(await queue.moveNext(), isTrue);
      expect(queue.current, {'id-2': 'Living Room'});

      await queue.cancel();
    });
  });
}
