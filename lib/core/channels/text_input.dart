import 'package:flixsy/core/errors/connect_failure.dart';

/// Remote text-injection capability exposed by transports whose TVs accept
/// inserted text into a focused field (currently planned: Roku, webOS,
/// Samsung, Android TV).
///
/// A transport advertises support by returning a non-null
/// [RemoteChannel.textInput]. The keyboard sheet keys off that nullability:
/// when it's `null` (no device connected, or the connected channel doesn't
/// implement this capability), the "Keyboard" button is hidden.
///
/// All methods complete with a typed [ConnectFailure] on failure — no
/// transport-specific exception escapes. The most common failure is
/// [CommandFailure]: not connected, or the TV currently has no text field
/// focused. Channels surface the TV-side error message on the [CommandFailure]
/// where one is available (webOS); the L10n layer maps it for the UI.
abstract interface class RemoteTextInput {
  /// Inserts [text] at the focused TV field's cursor, in order.
  ///
  /// Per-channel wire shape varies — Roku sends one HTTP POST per code point,
  /// webOS/Samsung/Android TV send a single message containing the whole
  /// string. Callers should treat this as a single logical operation and
  /// await its completion before sending the next text/backspace/submit.
  ///
  /// Empty [text] is a no-op.
  ///
  /// Throws [CommandFailure] if not connected or the TV rejects the input.
  Future<void> sendText(String text);

  /// Deletes one character to the left of the cursor (backspace).
  ///
  /// Throws [CommandFailure] if not connected or the TV rejects the input.
  Future<void> sendBackspace();

  /// Submits the field — ENTER on Roku/webOS/Samsung, `IME_ACTION_DONE` on
  /// Android TV. Typically closes the TV's on-screen keyboard and triggers
  /// the field's default action (run the search, log in, …).
  ///
  /// Throws [CommandFailure] if not connected or the TV rejects the input.
  Future<void> submit();

  /// Best-effort clear of the focused TV field.
  ///
  /// **Not all platforms support a true clear.** webOS and Android TV wipe
  /// the field in a single message and ignore [knownLength]. Roku and
  /// Samsung (when its empty-string path proves to be a no-op) fall back to
  /// emitting [knownLength] backspaces — so the caller must track how many
  /// characters this session has inserted and pass that count here. The
  /// keyboard session notifier tracks `sentLength` and supplies it.
  ///
  /// **Limitation:** [knownLength] only reflects text *we* sent. If the user
  /// has typed on the TV side first, the Roku/Samsung fallback under-deletes.
  ///
  /// Passing `knownLength: 0` makes the Roku/Samsung fallback a no-op.
  ///
  /// Throws [CommandFailure] if not connected or the TV rejects the input.
  Future<void> clear({int knownLength = 0});
}
