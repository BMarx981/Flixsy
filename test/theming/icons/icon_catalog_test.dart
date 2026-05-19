import 'package:flixsy/theming/icons/icon_catalog.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('standardPack', () {
    test('resolves a known icon id to its entry', () {
      final entry = standardPack.resolve('home');
      expect(entry, isNotNull);
      expect(entry!.name, 'Home');
    });

    test('returns null for an unknown icon id', () {
      expect(standardPack.resolve('nonexistent'), isNull);
    });

    test('is always unlocked', () {
      expect(standardPack.isUnlocked, isTrue);
    });

    test('entry ids are unique', () {
      final ids = [for (final e in standardPack.entries) e.id];
      expect(ids.toSet(), hasLength(ids.length));
    });
  });

  group('per-key defaults', () {
    test('every RemoteKey has a default icon present in the pack', () {
      for (final key in RemoteKey.values) {
        final id = defaultIconIdFor(key);
        expect(id, isNotNull, reason: '${key.name} has no default icon id');
        expect(
          standardPack.resolve(id!),
          isNotNull,
          reason: '${key.name} default icon "$id" is missing from the pack',
        );
      }
    });

    test('every RemoteKey has a non-empty default label', () {
      for (final key in RemoteKey.values) {
        expect(defaultLabel(key), isNotEmpty, reason: key.name);
      }
    });
  });

  group('resolvePackIcon', () {
    test('resolves an icon from the standard pack', () {
      expect(resolvePackIcon('standard', 'power'), isNotNull);
    });

    test('returns null for an unknown pack', () {
      expect(resolvePackIcon('mystery', 'power'), isNull);
    });

    test('returns null for an unknown icon in a known pack', () {
      expect(resolvePackIcon('standard', 'nonexistent'), isNull);
    });
  });
}
