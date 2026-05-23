import 'package:flixsy/core/channels/text_input.dart';
import 'package:flixsy/features/keyboard/widgets/keyboard_sheet.dart';
import 'package:flixsy/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps a host scaffold whose only button opens the keyboard sheet.
  Future<_RecordingTextInput> openSheet(WidgetTester tester) async {
    final input = _RecordingTextInput();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () =>
                      showKeyboardSheet(context, textInput: input),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return input;
  }

  testWidgets('renders title, TextField, and action buttons', (tester) async {
    await openSheet(tester);

    expect(find.text('Type to TV'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Send Enter'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('typing into the field ships sendText to the channel',
      (tester) async {
    final input = await openSheet(tester);

    await tester.enterText(find.byType(TextField), 'hi');
    // Let the notifier's send queue settle.
    await tester.pump();
    await tester.pump();

    expect(input.calls, contains('text:hi'));
  });

  testWidgets('Send Enter fires submit without closing the sheet',
      (tester) async {
    final input = await openSheet(tester);

    await tester.tap(find.text('Send Enter'));
    await tester.pump();
    await tester.pump();

    expect(input.calls, contains('submit'));
    // Sheet is still open: the TextField is still in the tree.
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Done closes the sheet', (tester) async {
    await openSheet(tester);
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
  });
}

class _RecordingTextInput implements RemoteTextInput {
  final List<String> calls = [];

  @override
  Future<void> sendText(String text) async => calls.add('text:$text');

  @override
  Future<void> sendBackspace() async => calls.add('bs');

  @override
  Future<void> submit() async => calls.add('submit');

  @override
  Future<void> clear({int knownLength = 0}) async =>
      calls.add('clear:$knownLength');
}
