import 'package:flixsy/data/models/tv_device.dart';
import 'package:flixsy/features/device_discovery/providers/device_display_names_provider.dart';
import 'package:flutter_test/flutter_test.dart';

TvDevice _device(String id, String name) =>
    TvDevice(id: id, name: name, ipAddress: '', modelName: '');

void main() {
  group('resolveDisplayNamesForTesting', () {
    test('returns the discovery name when no nickname is set', () {
      final result = resolveDisplayNamesForTesting(
        [_device('a', 'Living Room TV')],
        const {},
      );
      expect(result, {'a': 'Living Room TV'});
    });

    test('user nickname overrides the discovery name', () {
      final result = resolveDisplayNamesForTesting(
        [_device('a', 'Living Room TV')],
        const {'a': 'Den'},
      );
      expect(result, {'a': 'Den'});
    });

    test('duplicate names get (2), (3) suffixes; first keeps the bare name',
        () {
      final result = resolveDisplayNamesForTesting(
        [
          _device('id-3', 'Bedroom'),
          _device('id-1', 'Bedroom'),
          _device('id-2', 'Bedroom'),
        ],
        const {},
      );
      // Sorted by id: id-1 (bare), id-2 (2), id-3 (3).
      expect(result, {
        'id-1': 'Bedroom',
        'id-2': 'Bedroom (2)',
        'id-3': 'Bedroom (3)',
      });
    });

    test('suffix ordering is stable across input reshuffles', () {
      final shuffled = resolveDisplayNamesForTesting(
        [
          _device('id-2', 'TV'),
          _device('id-3', 'TV'),
          _device('id-1', 'TV'),
        ],
        const {},
      );
      final ordered = resolveDisplayNamesForTesting(
        [
          _device('id-1', 'TV'),
          _device('id-2', 'TV'),
          _device('id-3', 'TV'),
        ],
        const {},
      );
      expect(shuffled, ordered);
      expect(shuffled, {'id-1': 'TV', 'id-2': 'TV (2)', 'id-3': 'TV (3)'});
    });

    test('nicknames also collide and get suffixes', () {
      final result = resolveDisplayNamesForTesting(
        [
          _device('id-1', 'Original A'),
          _device('id-2', 'Original B'),
        ],
        const {'id-1': 'Den', 'id-2': 'Den'},
      );
      expect(result, {'id-1': 'Den', 'id-2': 'Den (2)'});
    });

    test('non-colliding nicknames coexist with non-renamed devices', () {
      final result = resolveDisplayNamesForTesting(
        [
          _device('id-1', 'Living Room'),
          _device('id-2', 'Kitchen TV'),
        ],
        const {'id-1': 'Den'},
      );
      expect(result, {'id-1': 'Den', 'id-2': 'Kitchen TV'});
    });

    test('empty input returns empty map', () {
      expect(resolveDisplayNamesForTesting(const [], const {}), isEmpty);
    });
  });
}
