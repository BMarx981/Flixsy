import '../errors/connect_failure.dart';
import 'pointer_control.dart';
import 'text_input.dart';

/// The platform-agnostic contract for discovering and controlling a TV.
///
/// Every transport implements this interface — the native ConnectSDK bridge
/// (`ConnectChannel`), the in-memory `FakeConnectChannel`, the per-vendor
/// pure-Dart channels (Roku, webOS, Samsung, Android TV), and the composite
/// that fans across them — so the rest of the app depends only on
/// `RemoteChannel`, never on a concrete transport.
///
/// ## Error contract
///
/// Every `Future`-returning method completes with a typed [ConnectFailure] on
/// failure. No transport-specific exception (`PlatformException`,
/// `SocketException`, `WebSocketException`, …) may escape an implementation.
///
/// ## Event contract
///
/// [deviceEvents] is a broadcast stream of untyped maps. Each event carries a
/// `String` `type` key; consumers (see `DeviceDiscoveryNotifier`) handle:
///
/// | `type`                   | Payload keys                                      |
/// |--------------------------|---------------------------------------------------|
/// | `deviceFound`            | `device`: `{id, name, ipAddress, modelName}`      |
/// | `deviceUpdated`          | `device`: same shape                              |
/// | `deviceLost`             | `deviceId`: `String`                              |
/// | `connectionStateChanged` | `state`: `connected` \| `disconnected` \| `error` |
/// | `discoveryError`         | `message`: `String`                              |
/// | `pairingRequired`        | `deviceId`: `String`, `kind`: `confirmOnTv` \| `enterCode` |
abstract interface class RemoteChannel {
  /// Broadcast stream of discovery and connection events. See the class doc
  /// for the event-map shape.
  Stream<Map<String, dynamic>> get deviceEvents;

  /// Starts scanning the local network for TVs. Results arrive asynchronously
  /// as `deviceFound` events on [deviceEvents].
  ///
  /// Throws [DiscoveryFailure] if the scan cannot be started.
  Future<void> startDiscovery();

  /// Stops an in-progress scan. A no-op when no scan is running.
  Future<void> stopDiscovery();

  /// Connects to the device with the given [deviceId] — an `id` previously
  /// surfaced by a `deviceFound` event.
  ///
  /// First-time pairing emits a `pairingRequired` event, and the returned
  /// future stays pending until the user completes it — by accepting a prompt
  /// on the TV, or by entering a code via [submitPairingCode].
  ///
  /// Throws [ConnectionFailure] if the connection or pairing fails.
  Future<void> connectToDevice(String deviceId);

  /// Submits a pairing [code] the user read off the TV, in response to a
  /// `pairingRequired` event of kind `enterCode` (Android TV); lets the
  /// in-flight [connectToDevice] continue.
  ///
  /// Throws [ConnectionFailure] if no code-based pairing is in progress.
  Future<void> submitPairingCode(String code);

  /// Disconnects from the currently connected device. A no-op when not
  /// connected.
  Future<void> disconnect();

  /// Sends a single remote-control key command (e.g. `UP`, `HOME`,
  /// `VOLUME_UP`) to the connected device.
  ///
  /// Throws [CommandFailure] if not connected or the command is rejected.
  Future<void> sendKeyCommand(String key);

  /// Returns a snapshot of the devices discovered so far in the current scan.
  ///
  /// Throws [DiscoveryFailure] if the snapshot cannot be retrieved.
  Future<List<Map<String, dynamic>>> getDiscoveredDevices();

  /// Releases all resources — open sockets, the event stream controller, and
  /// any platform handles. The instance must not be used afterwards.
  ///
  /// Wire this into the owning provider's `ref.onDispose`.
  void dispose();

  /// Free-cursor / accelerometer-pointer capability, if the currently
  /// connected device supports it. Returns `null` otherwise — widgets check
  /// this nullability to decide whether to surface the LG-style pointer
  /// gesture (long-press OK on the D-pad).
  PointerControl? get pointerControl => null;

  /// Remote text-injection capability, if the currently connected device
  /// supports typing into a focused TV field. Returns `null` otherwise —
  /// the keyboard sheet keys off this nullability to hide its "Keyboard"
  /// button when no text-capable device is connected.
  RemoteTextInput? get textInput => null;
}
