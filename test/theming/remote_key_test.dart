import 'package:flixsy/theming/remote_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteKey catalog', () {
    test('every key has a unique wire code', () {
      final codes = RemoteKey.values.map((k) => k.code).toList();
      expect(codes.toSet(), hasLength(codes.length));
    });

    // The wire codes are a contract with the channel layer: every
    // RemoteChannel translation map keys off these exact strings. Pinning
    // them here catches an accidental rename before it reaches a device.
    test('wire codes are the expected upper-snake-case strings', () {
      expect(RemoteKey.up.code, 'UP');
      expect(RemoteKey.down.code, 'DOWN');
      expect(RemoteKey.left.code, 'LEFT');
      expect(RemoteKey.right.code, 'RIGHT');
      expect(RemoteKey.ok.code, 'OK');
      expect(RemoteKey.back.code, 'BACK');
      expect(RemoteKey.home.code, 'HOME');
      expect(RemoteKey.rewind.code, 'REWIND');
      expect(RemoteKey.playPause.code, 'PLAY_PAUSE');
      expect(RemoteKey.fastForward.code, 'FAST_FORWARD');
      expect(RemoteKey.next.code, 'NEXT');
      expect(RemoteKey.previous.code, 'PREVIOUS');
      expect(RemoteKey.volumeUp.code, 'VOLUME_UP');
      expect(RemoteKey.volumeDown.code, 'VOLUME_DOWN');
      expect(RemoteKey.mute.code, 'MUTE');
      expect(RemoteKey.power.code, 'POWER');
    });

    test('each key carries a role', () {
      expect(
        RemoteKey.values.map((k) => k.role),
        everyElement(isA<RemoteKeyRole>()),
      );
      expect(RemoteKey.up.role, RemoteKeyRole.dpad);
      expect(RemoteKey.home.role, RemoteKeyRole.navigation);
      expect(RemoteKey.fastForward.role, RemoteKeyRole.transport);
      expect(RemoteKey.mute.role, RemoteKeyRole.volume);
      expect(RemoteKey.power.role, RemoteKeyRole.system);
    });
  });
}
