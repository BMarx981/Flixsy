import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/channels/pointer_control.dart';
import '../../../core/errors/connect_failure.dart';
import '../../../shared/providers/app_providers.dart';

/// [PointerControl] for the currently connected TV, or `null` when the device
/// has no free-cursor capability (anything other than webOS today).
///
/// Skin widgets watch this provider to decide whether to expose the
/// long-press-OK pointer gesture on the D-pad.
final pointerControlProvider = Provider<PointerControl?>((ref) {
  return ref.watch(remoteChannelProvider).pointerControl;
});

/// Map of gyroscope angular velocity (rad/s) to webOS pointer pixels.
///
/// At a typical hand-aim speed of ~1 rad/s, this yields ~600 px/s — fast
/// enough to traverse a 1080p UI in under two seconds without overshooting
/// menu items at slower speeds.
const double _gyroToPixels = 600;

/// Minimum interval between pointer frames sent to the TV. Gyro events arrive
/// at ~60–200 Hz depending on platform; we coalesce deltas to keep the
/// over-the-air rate sane (~50 Hz max).
const Duration _frameInterval = Duration(milliseconds: 20);

/// Owns the active free-cursor session: gyro subscription, delta throttling,
/// and forwarding to the TV's [PointerControl].
///
/// State is `true` while a session is active. Widgets call [start] on long-
/// press of OK and [stop] on release; the centre tap during a session is
/// routed through [click] so it activates whatever the cursor is hovering
/// over rather than the focused element.
class PointerSessionNotifier extends Notifier<bool> {
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Timer? _frameTimer;
  double _pendingDx = 0;
  double _pendingDy = 0;

  @visibleForTesting
  Stream<GyroscopeEvent> Function() gyroStreamFactory =
      () => gyroscopeEventStream();

  @override
  bool build() {
    ref.onDispose(_teardown);
    return false;
  }

  /// Begins streaming gyro deltas to the TV's pointer. No-op if a session is
  /// already active or the connected device doesn't support pointer input.
  Future<void> start() async {
    if (state) return;
    final pointer = ref.read(pointerControlProvider);
    if (pointer == null) return;

    try {
      await pointer.connectPointer();
    } on ConnectFailure catch (error) {
      debugPrint('[PointerSession] connectPointer failed: ${error.message}');
      return;
    }

    _gyroSub = gyroStreamFactory().listen(_onGyro);
    _frameTimer = Timer.periodic(_frameInterval, (_) => _flush(pointer));
    state = true;
  }

  /// Stops the session and releases the gyro subscription. Safe to call when
  /// no session is active.
  Future<void> stop() async {
    if (!state) return;
    _teardown();
    final pointer = ref.read(pointerControlProvider);
    if (pointer != null) {
      try {
        await pointer.disconnectPointer();
      } on ConnectFailure catch (error) {
        debugPrint(
          '[PointerSession] disconnectPointer failed: ${error.message}',
        );
      }
    }
    state = false;
  }

  /// Fires a click at the cursor's current position. Called when the user
  /// taps OK while a pointer session is active.
  Future<void> click() async {
    final pointer = ref.read(pointerControlProvider);
    if (pointer == null) return;
    try {
      await pointer.sendPointerClick();
    } on ConnectFailure catch (error) {
      debugPrint('[PointerSession] sendPointerClick failed: ${error.message}');
    }
  }

  void _onGyro(GyroscopeEvent event) {
    // Map phone rotation to screen motion: rotating right around the Y axis
    // (yaw) moves the cursor right; pitching the phone up (around X) moves
    // the cursor up. Signs are tuned so a natural aim gesture goes the
    // expected direction on the TV.
    _pendingDx += -event.y * _gyroToPixels * _frameInterval.inMilliseconds / 1000;
    _pendingDy += -event.x * _gyroToPixels * _frameInterval.inMilliseconds / 1000;
  }

  void _flush(PointerControl pointer) {
    if (_pendingDx.abs() < 0.5 && _pendingDy.abs() < 0.5) return;
    final dx = _pendingDx;
    final dy = _pendingDy;
    _pendingDx = 0;
    _pendingDy = 0;
    pointer.sendPointerMove(dx, dy).catchError((Object error) {
      debugPrint('[PointerSession] sendPointerMove failed: $error');
    });
  }

  void _teardown() {
    _frameTimer?.cancel();
    _frameTimer = null;
    _gyroSub?.cancel();
    _gyroSub = null;
    _pendingDx = 0;
    _pendingDy = 0;
  }
}

final pointerSessionProvider =
    NotifierProvider<PointerSessionNotifier, bool>(PointerSessionNotifier.new);
