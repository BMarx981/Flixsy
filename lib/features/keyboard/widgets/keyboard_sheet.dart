import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/channels/text_input.dart';
import '../../../core/errors/connect_failure.dart';
import '../../../core/extensions/l10n_extensions.dart';
import '../providers/keyboard_session_provider.dart';

/// Opens the keyboard bottom sheet against [textInput]. The OS keyboard
/// handles the actual character entry; this sheet just funnels the resulting
/// TextField edits into the [keyboardSessionProvider] which then ships them
/// to the TV.
Future<void> showKeyboardSheet(
  BuildContext context, {
  required RemoteTextInput textInput,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => _KeyboardSheet(textInput: textInput),
  );
}

class _KeyboardSheet extends ConsumerStatefulWidget {
  const _KeyboardSheet({required this.textInput});

  final RemoteTextInput textInput;

  @override
  ConsumerState<_KeyboardSheet> createState() => _KeyboardSheetState();
}

class _KeyboardSheetState extends ConsumerState<_KeyboardSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Bring up the OS keyboard immediately so the user starts typing without
    // a second tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    ref
        .read(keyboardSessionProvider.notifier)
        .applyEdit(value, widget.textInput);
  }

  Future<void> _onSubmitted() async {
    await ref
        .read(keyboardSessionProvider.notifier)
        .submit(widget.textInput);
  }

  void _onClose() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    // Surface send failures as a snackbar inside the host scaffold without
    // closing the sheet — the user might want to retry.
    ref.listen<ConnectFailure?>(
      keyboardSessionProvider.select((s) => s.failure),
      (prev, next) {
        if (next != null && next != prev) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.failureMessage(next)),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
    );

    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        // Lift the sheet above the OS keyboard.
        bottom: viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.keyboardTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.send,
            maxLines: 3,
            minLines: 1,
            onChanged: _onChanged,
            onSubmitted: (_) async {
              await _onSubmitted();
              if (mounted) _onClose();
            },
            decoration: InputDecoration(
              hintText: context.l10n.keyboardHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _onSubmitted,
                  child: Text(context.l10n.keyboardSendEnter),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: _onClose,
                  child: Text(context.l10n.keyboardClose),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
