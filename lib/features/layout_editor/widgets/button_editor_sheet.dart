import 'package:flutter/material.dart';

import '../../../data/models/layout/button_appearance.dart';
import '../../../data/models/layout/remote_button.dart';
import '../../../theming/icons/icon_catalog.dart';
import '../../../theming/remote_key.dart';
import '../../../theming/standard/button_presentation.dart';
import 'action_picker_sheet.dart';
import 'icon_picker_sheet.dart';

/// Shows a bottom sheet to edit one button — its action, its icon, and its
/// label — and resolves to the edited [RemoteButton], or `null` if dismissed
/// without confirming.
///
/// Action and appearance are independent (design doc §3): changing one never
/// disturbs the other.
Future<RemoteButton?> showButtonEditorSheet(
  BuildContext context, {
  required RemoteButton button,
}) {
  return showModalBottomSheet<RemoteButton>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _ButtonEditorSheet(button: button),
  );
}

class _ButtonEditorSheet extends StatefulWidget {
  const _ButtonEditorSheet({required this.button});

  final RemoteButton button;

  @override
  State<_ButtonEditorSheet> createState() => _ButtonEditorSheetState();
}

class _ButtonEditorSheetState extends State<_ButtonEditorSheet> {
  late RemoteKey _action = widget.button.action;
  late ButtonAppearance _appearance = widget.button.appearance;
  late bool _showLabel;
  late final TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    final override = widget.button.appearance.labelOverride;
    // labelOverride: null = default, '' = hidden, else custom text.
    _showLabel = override != '';
    _labelController = TextEditingController(
      text: (override == null || override.isEmpty) ? '' : override,
    );
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  /// Folds the label controls back into a [ButtonAppearance.labelOverride]:
  /// hidden → `''`, empty field → `null` (use the key default), else the text.
  String? get _labelOverride {
    if (!_showLabel) return '';
    final text = _labelController.text;
    return text.isEmpty ? null : text;
  }

  /// The button as currently edited — appearance kind plus the live label.
  RemoteButton get _button => RemoteButton(
    action: _action,
    appearance: _appearance.withLabelOverride(_labelOverride),
  );

  Future<void> _editAction() async {
    final key = await showActionPickerSheet(context);
    if (key != null && mounted) setState(() => _action = key);
  }

  Future<void> _editIcon() async {
    final appearance = await showIconPickerSheet(
      context,
      action: _action,
      current: _appearance,
    );
    if (appearance != null && mounted) {
      setState(() => _appearance = appearance);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glyph = resolveButton(_button).glyph;
    final iconLeading = switch (glyph) {
      IconGlyph(:final icon) => Icon(icon),
      TextGlyph() => const Icon(Icons.text_fields),
    };

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('Edit button', style: theme.textTheme.titleMedium),
            ),
            ListTile(
              leading: Icon(defaultIconFor(_action)),
              title: const Text('Action'),
              subtitle: Text(defaultLabel(_action)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _editAction,
            ),
            ListTile(
              leading: iconLeading,
              title: const Text('Icon'),
              subtitle: Text(_appearanceDescription),
              trailing: const Icon(Icons.chevron_right),
              onTap: _editIcon,
            ),
            const Divider(height: 16),
            SwitchListTile(
              title: const Text('Show label'),
              subtitle: Text(
                _showLabel
                    ? 'A caption is shown on the button'
                    : 'The button shows no caption',
              ),
              value: _showLabel,
              onChanged: (value) => setState(() => _showLabel = value),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _labelController,
                enabled: _showLabel,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Label',
                  border: const OutlineInputBorder(),
                  hintText: defaultLabel(_action),
                  helperText: _showLabel && _labelController.text.isEmpty
                      ? 'Empty — using the default: ${defaultLabel(_action)}'
                      : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_button),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A short human-readable description of the chosen appearance kind.
  String get _appearanceDescription => switch (_appearance) {
    DefaultLook() => 'Default',
    TextOnly() => 'Text only',
    BuiltInIcon(:final iconId) =>
      standardPack.resolve(iconId)?.name ?? 'Custom icon',
    PackIcon() => 'Pack icon',
    CustomImage() => 'Custom image',
  };
}
