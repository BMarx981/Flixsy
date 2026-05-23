import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/channels/text_input.dart';
import '../../../core/errors/connect_failure.dart';

/// Diff between two consecutive text snapshots, expressed as the work needed
/// to bring the TV-side field in sync: delete [backspaces] code points, then
/// insert [toAppend] code points at the cursor.
///
/// Exposed for unit testing — production code goes through
/// [KeyboardSessionNotifier.applyEdit].
class KeyboardEdit {
  const KeyboardEdit({required this.backspaces, required this.toAppend});

  final int backspaces;
  final String toAppend;

  /// True when this edit is a no-op (nothing to delete, nothing to insert).
  bool get isEmpty => backspaces == 0 && toAppend.isEmpty;
}

/// Computes the [KeyboardEdit] that turns [prev] into [next] using the
/// longest-common-prefix strategy.
///
/// **Boundary correctness for surrogate pairs.** Common prefix length is
/// first taken in UTF-16 code units (cheap, well-defined), then trimmed back
/// by one if it would split a surrogate pair (i.e. it ends on a high
/// surrogate while the next code unit in both strings differs — only the case
/// where they'd differ matters for triggering this). The backspace count is
/// then the number of **code points** in `prev.substring(prefix)`, not code
/// units — Roku's `Backspace` deletes one code point at a time, and an emoji
/// (one code point but two code units) must count as one backspace, not two.
KeyboardEdit computeEdit(String prev, String next) {
  if (identical(prev, next) || prev == next) {
    return const KeyboardEdit(backspaces: 0, toAppend: '');
  }

  var prefix = 0;
  final maxPrefix = prev.length < next.length ? prev.length : next.length;
  while (prefix < maxPrefix && prev.codeUnitAt(prefix) == next.codeUnitAt(prefix)) {
    prefix++;
  }

  // If the prefix lands mid-surrogate (ends on a high surrogate), back it off
  // by one so we never split a surrogate pair across the prefix/suffix line.
  if (prefix > 0 && prefix < prev.length) {
    final code = prev.codeUnitAt(prefix - 1);
    if (code >= 0xD800 && code <= 0xDBFF) {
      prefix--;
    }
  }

  // Code points (not code units) in the removed portion of [prev].
  final removed = prev.substring(prefix);
  final backspaces = removed.runes.length;
  final toAppend = next.substring(prefix);
  return KeyboardEdit(backspaces: backspaces, toAppend: toAppend);
}

/// Ephemeral state of one open keyboard sheet.
class KeyboardSessionState {
  const KeyboardSessionState({
    required this.lastSentText,
    required this.sentLength,
    this.failure,
  });

  /// The snapshot of the field as last successfully sent to the TV. Diff
  /// against this on the next edit to decide what to backspace/insert.
  final String lastSentText;

  /// Number of code points this session believes it has inserted on the TV.
  /// Passed to [RemoteTextInput.clear] so the Roku/Samsung fallback can size
  /// its backspace burst without over-deleting.
  final int sentLength;

  /// The most recent [ConnectFailure], or `null` after a successful send.
  /// The sheet surfaces it as a snackbar.
  final ConnectFailure? failure;

  KeyboardSessionState copyWith({
    String? lastSentText,
    int? sentLength,
    ConnectFailure? failure,
    bool clearFailure = false,
  }) {
    return KeyboardSessionState(
      lastSentText: lastSentText ?? this.lastSentText,
      sentLength: sentLength ?? this.sentLength,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

/// Owns one open keyboard sheet's send queue and diff state.
///
/// Created fresh every time the sheet opens (autoDispose). Callers feed every
/// `TextField.onChanged` value into [applyEdit]; the notifier diffs against
/// the last-sent snapshot and serialises the resulting backspace/insert pair
/// behind a single in-flight future, so a slow Roku doesn't see edits
/// interleaved out of order.
class KeyboardSessionNotifier extends AutoDisposeNotifier<KeyboardSessionState> {
  /// Single in-flight send chain — every new edit appends to its tail. This
  /// is the back-pressure mechanism: while one POST sequence is outstanding,
  /// later keystrokes line up behind it instead of racing.
  Future<void> _pending = Future.value();

  /// The text we **intend** to have sent. Diff is computed against this, not
  /// against [KeyboardSessionState.lastSentText], so queued edits compose
  /// correctly. State.lastSentText only updates after a send actually lands.
  String _targetText = '';

  /// Mirrors [_targetText]'s code-point count for the [clear] fallback.
  int _targetLength = 0;

  @override
  KeyboardSessionState build() {
    ref.onDispose(() {
      // Best-effort: future sends after dispose are dropped. The sheet
      // already closed, and the TV field will be in whatever state the last
      // successful send left it.
    });
    return const KeyboardSessionState(lastSentText: '', sentLength: 0);
  }

  /// Feeds a new [TextField] snapshot into the session.
  ///
  /// The diff is computed immediately against [_targetText] — the text we're
  /// already in the process of sending — and the resulting backspace/insert
  /// pair is appended to the in-flight queue. The TextField is the source of
  /// truth for what the user wants typed; this notifier is just the conveyor
  /// belt to the TV.
  void applyEdit(String next, RemoteTextInput textInput) {
    final edit = computeEdit(_targetText, next);
    if (edit.isEmpty) return;

    _targetText = next;
    _targetLength = next.runes.length;

    _pending = _pending.then((_) => _flush(edit, next, textInput));
  }

  Future<void> _flush(
    KeyboardEdit edit,
    String snapshot,
    RemoteTextInput textInput,
  ) async {
    try {
      for (var i = 0; i < edit.backspaces; i++) {
        await textInput.sendBackspace();
      }
      if (edit.toAppend.isNotEmpty) {
        await textInput.sendText(edit.toAppend);
      }
      // Update what's been confirmed-sent only after a successful flush.
      state = state.copyWith(
        lastSentText: snapshot,
        sentLength: snapshot.runes.length,
        clearFailure: true,
      );
    } on ConnectFailure catch (failure) {
      state = state.copyWith(failure: failure);
    }
  }

  /// Submits the field — ENTER on Roku/webOS/Samsung, IME_ACTION_DONE on
  /// Android TV. Queued behind any pending edit so the submit lands after
  /// the text it's submitting.
  Future<void> submit(RemoteTextInput textInput) {
    final task = _pending.then((_) async {
      try {
        await textInput.submit();
        if (state.failure != null) {
          state = state.copyWith(clearFailure: true);
        }
      } on ConnectFailure catch (failure) {
        state = state.copyWith(failure: failure);
      }
    });
    _pending = task;
    return task;
  }

  /// Clears the TV field. Sized to [_targetLength] so the Roku/Samsung
  /// fallback knows how many backspaces to emit.
  Future<void> clear(RemoteTextInput textInput) {
    final knownLength = _targetLength;
    _targetText = '';
    _targetLength = 0;
    final task = _pending.then((_) async {
      try {
        await textInput.clear(knownLength: knownLength);
        state = state.copyWith(
          lastSentText: '',
          sentLength: 0,
          clearFailure: true,
        );
      } on ConnectFailure catch (failure) {
        state = state.copyWith(failure: failure);
      }
    });
    _pending = task;
    return task;
  }
}

final keyboardSessionProvider =
    AutoDisposeNotifierProvider<KeyboardSessionNotifier, KeyboardSessionState>(
      KeyboardSessionNotifier.new,
    );
