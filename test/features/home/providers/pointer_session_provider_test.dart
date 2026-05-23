import 'dart:async';

import 'package:flixsy/core/channels/pointer_control.dart';
import 'package:flixsy/features/home/providers/pointer_session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

class _FakePointerControl implements PointerControl {
  bool connected = false;
  final List<Offset> moves = [];
  int clicks = 0;

  @override
  Future<void> connectPointer() async {
    connected = true;
  }

  @override
  Future<void> disconnectPointer() async {
    connected = false;
  }

  @override
  Future<void> sendPointerMove(double dx, double dy) async {
    moves.add(Offset(dx, dy));
  }

  @override
  Future<void> sendPointerClick() async {
    clicks++;
  }
}

void main() {
  // sendPointerMove is rate-limited by _frameInterval; pump long enough that
  // at least one flush happens.
  const flushWait = Duration(milliseconds: 60);

  ProviderContainer makeContainer({required _FakePointerControl? pointer}) {
    return ProviderContainer(
      overrides: [
        pointerControlProvider.overrideWithValue(pointer),
      ],
    );
  }

  test('start with no pointer support is a no-op', () async {
    final container = makeContainer(pointer: null);
    addTearDown(container.dispose);

    final notifier = container.read(pointerSessionProvider.notifier);
    await notifier.start();

    expect(container.read(pointerSessionProvider), isFalse);
  });

  test('start opens the pointer and toggles state', () async {
    final pointer = _FakePointerControl();
    final container = makeContainer(pointer: pointer);
    addTearDown(container.dispose);

    final notifier = container.read(pointerSessionProvider.notifier);
    final gyroController = StreamController<GyroscopeEvent>.broadcast();
    addTearDown(gyroController.close);
    notifier.gyroStreamFactory = () => gyroController.stream;

    await notifier.start();

    expect(pointer.connected, isTrue);
    expect(container.read(pointerSessionProvider), isTrue);
  });

  test(
    'gyro events accumulate into throttled sendPointerMove calls',
    () async {
      final pointer = _FakePointerControl();
      final container = makeContainer(pointer: pointer);
      addTearDown(container.dispose);

      final notifier = container.read(pointerSessionProvider.notifier);
      final gyroController = StreamController<GyroscopeEvent>.broadcast();
      addTearDown(gyroController.close);
      notifier.gyroStreamFactory = () => gyroController.stream;

      await notifier.start();

      // Inject several gyro samples — accumulated deltas get flushed on the
      // next frame tick.
      gyroController.add(GyroscopeEvent(0.5, 0.3, 0, DateTime.now()));
      gyroController.add(GyroscopeEvent(0.5, 0.3, 0, DateTime.now()));
      await Future<void>.delayed(flushWait);

      expect(pointer.moves, isNotEmpty);
      // Yaw (event.y, positive) maps to leftward cursor motion: negative dx.
      expect(pointer.moves.first.dx, lessThan(0));
      // Pitch (event.x, positive) maps to upward cursor motion: negative dy.
      expect(pointer.moves.first.dy, lessThan(0));
    },
  );

  test('stop tears down the session and disconnects the pointer', () async {
    final pointer = _FakePointerControl();
    final container = makeContainer(pointer: pointer);
    addTearDown(container.dispose);

    final notifier = container.read(pointerSessionProvider.notifier);
    final gyroController = StreamController<GyroscopeEvent>.broadcast();
    addTearDown(gyroController.close);
    notifier.gyroStreamFactory = () => gyroController.stream;

    await notifier.start();
    await notifier.stop();

    expect(container.read(pointerSessionProvider), isFalse);
    expect(pointer.connected, isFalse);

    // Gyro events after stop must not produce more moves.
    final before = pointer.moves.length;
    gyroController.add(GyroscopeEvent(1, 1, 0, DateTime.now()));
    await Future<void>.delayed(flushWait);
    expect(pointer.moves.length, before);
  });

  test('click forwards to sendPointerClick', () async {
    final pointer = _FakePointerControl();
    final container = makeContainer(pointer: pointer);
    addTearDown(container.dispose);

    final notifier = container.read(pointerSessionProvider.notifier);
    await notifier.click();

    expect(pointer.clicks, 1);
  });
}
