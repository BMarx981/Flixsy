import '../errors/connect_failure.dart';

/// Free-cursor / accelerometer-pointer capability exposed by transports that
/// support an LG Magic Remote-style arrow (currently webOS).
///
/// A transport advertises support by returning a non-null
/// [RemoteChannel.pointerControl]. Widgets check that nullability to decide
/// whether to surface the long-press-OK pointer gesture.
///
/// All methods complete with a typed [ConnectFailure] on failure — no
/// transport-specific exception escapes.
abstract interface class PointerControl {
  /// Prepares the pointer stream for use. For webOS the pointer socket is
  /// already opened during [RemoteChannel.connectToDevice], so this is a
  /// no-op; other transports may open a dedicated channel here.
  ///
  /// Throws [CommandFailure] if no device is currently connected.
  Future<void> connectPointer();

  /// Moves the cursor by the relative deltas [dx], [dy] in device-pixel-ish
  /// units. Positive [dx] is right, positive [dy] is down.
  ///
  /// Callers are expected to throttle — transports forward each call as a
  /// single frame to the TV, with no rate-limiting of their own.
  ///
  /// Throws [CommandFailure] if the pointer stream is not available.
  Future<void> sendPointerMove(double dx, double dy);

  /// Clicks at the cursor's current position. On webOS this is distinct from
  /// `sendKeyCommand('OK')` — the pointer click activates whatever the arrow
  /// is hovering over, while an ENTER key targets the focused element.
  ///
  /// Throws [CommandFailure] if the pointer stream is not available.
  Future<void> sendPointerClick();

  /// Releases any session-scoped resources. The pointer socket itself stays
  /// owned by the transport and is torn down on [RemoteChannel.disconnect].
  Future<void> disconnectPointer();
}
