import 'package:flixsy/core/channels/text_input.dart';
import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flixsy/features/keyboard/providers/keyboard_session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeEdit', () {
    test('empty prev + non-empty next: insert only, no backspaces', () {
      final edit = computeEdit('', 'hello');
      expect(edit.backspaces, 0);
      expect(edit.toAppend, 'hello');
    });

    test('append: only the new tail is inserted', () {
      final edit = computeEdit('hello', 'hello world');
      expect(edit.backspaces, 0);
      expect(edit.toAppend, ' world');
    });

    test('delete from end: backspaces only, nothing to append', () {
      final edit = computeEdit('hello', 'hel');
      expect(edit.backspaces, 2);
      expect(edit.toAppend, '');
    });

    test('delete to empty: backspace every code point in prev', () {
      final edit = computeEdit('abc', '');
      expect(edit.backspaces, 3);
      expect(edit.toAppend, '');
    });

    test('replace tail: backspace divergent tail, insert new tail', () {
      // prev = "hello", next = "help" → common prefix "hel"
      final edit = computeEdit('hello', 'help');
      expect(edit.backspaces, 2);
      expect(edit.toAppend, 'p');
    });

    test('middle edit collapses to "backspace to prefix, retype tail"', () {
      // prev = "abcdef", next = "abZef" → common prefix "ab", delete "cdef",
      // type "Zef". This is what mid-string edits become — not minimal in
      // backspaces, but correct and simple.
      final edit = computeEdit('abcdef', 'abZef');
      expect(edit.backspaces, 4);
      expect(edit.toAppend, 'Zef');
    });

    test('identical strings: no-op (empty edit)', () {
      final edit = computeEdit('hello', 'hello');
      expect(edit.isEmpty, isTrue);
    });

    test('empty -> empty: no-op', () {
      final edit = computeEdit('', '');
      expect(edit.isEmpty, isTrue);
    });

    test(
      'surrogate pair stays atomic — typing emoji = 1 backspace to delete',
      () {
        // 😀 = U+1F600, one code point, two UTF-16 code units.
        final typed = computeEdit('a', 'a\u{1F600}');
        expect(typed.backspaces, 0);
        expect(typed.toAppend, '\u{1F600}');

        final deleted = computeEdit('a\u{1F600}', 'a');
        expect(deleted.backspaces, 1, reason: 'one code point, one backspace');
        expect(deleted.toAppend, '');
      },
    );

    test(
      'differing emoji with the same high surrogate does not split a pair',
      () {
        // 😀 = U+1F600 = D83D DE00, 😁 = U+1F601 = D83D DE01.
        // Naive code-unit prefix is 4 ('a', 'b', high, low... wait, lows
        // differ). Common code-unit prefix is 3 ('a', 'b', high). The
        // boundary-correction step must trim that back to 2 so we don't ask
        // sendText('\uDE01...') with a stranded low surrogate.
        const prev = 'ab\u{1F600}c';
        const next = 'ab\u{1F601}c';
        final edit = computeEdit(prev, next);

        // The emoji + 'c' must be backspaced (2 code points) and re-inserted.
        expect(edit.backspaces, 2);
        expect(edit.toAppend, '\u{1F601}c');
        // toAppend must start with a full code point — not a stranded low
        // surrogate (0xDC00–0xDFFF).
        final firstCu = edit.toAppend.codeUnitAt(0);
        expect(
          firstCu < 0xDC00 || firstCu > 0xDFFF,
          isTrue,
          reason: 'toAppend must not start with a low surrogate',
        );
      },
    );
  });

  group('KeyboardSessionNotifier', () {
    test('applyEdit serialises one text snapshot into backspaces + inserts',
        () async {
      final input = _RecordingTextInput();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(keyboardSessionProvider.notifier);

      notifier.applyEdit('hi', input);
      await input.drain();

      expect(input.calls, ['text:hi']);
      final state = container.read(keyboardSessionProvider);
      expect(state.lastSentText, 'hi');
      expect(state.sentLength, 2);
    });

    test('two edits in flight stay ordered — diff composes', () async {
      final input = _RecordingTextInput();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(keyboardSessionProvider.notifier);

      // Fire two edits back-to-back: simulates user typing fast while the
      // first send is still on the wire. The diff for the second is computed
      // against _targetText (already updated to "hi"), so the second call
      // ships only the new tail.
      notifier.applyEdit('hi', input);
      notifier.applyEdit('hi!', input);
      await input.drain();

      expect(input.calls, ['text:hi', 'text:!']);
    });

    test('backspace path: prev "hello", next "hel" emits 2 sendBackspace',
        () async {
      final input = _RecordingTextInput();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(keyboardSessionProvider.notifier);

      notifier.applyEdit('hello', input);
      await input.drain();
      input.calls.clear();

      notifier.applyEdit('hel', input);
      await input.drain();

      expect(input.calls, ['bs', 'bs']);
    });

    test('submit awaits any pending edit and forwards to textInput',
        () async {
      final input = _RecordingTextInput();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(keyboardSessionProvider.notifier);

      notifier.applyEdit('hello', input);
      await notifier.submit(input);

      // The submit must land *after* the text, not before.
      expect(input.calls, ['text:hello', 'submit']);
    });

    test('clear forwards the running sentLength as knownLength', () async {
      final input = _RecordingTextInput();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(keyboardSessionProvider.notifier);

      notifier.applyEdit('hello', input);
      await input.drain();

      await notifier.clear(input);

      expect(input.lastClearKnownLength, 5);
      final state = container.read(keyboardSessionProvider);
      expect(state.sentLength, 0);
      expect(state.lastSentText, '');
    });

    test('a failed send surfaces the ConnectFailure on state', () async {
      final input = _RecordingTextInput(
        failTextOnce: const CommandFailure('boom'),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(keyboardSessionProvider.notifier);

      notifier.applyEdit('hi', input);
      await input.drain();

      final state = container.read(keyboardSessionProvider);
      expect(state.failure, isA<CommandFailure>());
    });

    test('a successful send after a failure clears the failure', () async {
      final input = _RecordingTextInput(
        failTextOnce: const CommandFailure('boom'),
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(keyboardSessionProvider.notifier);

      notifier.applyEdit('hi', input);
      await input.drain();
      expect(container.read(keyboardSessionProvider).failure, isNotNull);

      // Second edit succeeds (failTextOnce only fails once).
      notifier.applyEdit('hi!', input);
      await input.drain();

      expect(container.read(keyboardSessionProvider).failure, isNull);
    });
  });
}

/// [RemoteTextInput] that records every call as a tagged string and exposes
/// an awaitable [drain] for tests that want to wait until the in-flight queue
/// settles.
class _RecordingTextInput implements RemoteTextInput {
  _RecordingTextInput({this.failTextOnce});

  /// When set, the next [sendText] throws this once, then resumes normal
  /// behaviour. Used to test failure surfacing + recovery.
  ConnectFailure? failTextOnce;

  final List<String> calls = [];
  int? lastClearKnownLength;

  /// Awaits until the notifier's `_pending` future is settled. Trick: enqueue
  /// our own microtask after the current task chain and wait for it.
  Future<void> drain() async {
    // Two awaits give Riverpod's async glue a chance to settle the state
    // update inside .then() callbacks.
    await Future<void>.value();
    await Future<void>.value();
  }

  @override
  Future<void> sendText(String text) async {
    final failure = failTextOnce;
    if (failure != null) {
      failTextOnce = null;
      throw failure;
    }
    calls.add('text:$text');
  }

  @override
  Future<void> sendBackspace() async {
    calls.add('bs');
  }

  @override
  Future<void> submit() async {
    calls.add('submit');
  }

  @override
  Future<void> clear({int knownLength = 0}) async {
    lastClearKnownLength = knownLength;
    calls.add('clear:$knownLength');
  }
}
