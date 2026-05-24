import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:flixsy/data/models/layout/button_appearance.dart';
import 'package:flixsy/data/models/layout/remote_button.dart';
import 'package:flixsy/theming/custom_image_provider.dart';
import 'package:flixsy/theming/icons/icon_catalog.dart';
import 'package:flixsy/theming/icons/remote_key_l10n.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flixsy/theming/standard/button_presentation.dart';
import 'package:flixsy/features/layout_editor/widgets/action_picker_sheet.dart';
import 'package:flixsy/features/layout_editor/widgets/glass_sheet.dart';
import 'package:flixsy/features/layout_editor/widgets/icon_picker_sheet.dart';

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
  return showGlassModalBottomSheet<RemoteButton>(
    context: context,
    builder: (sheetContext) => _ButtonEditorSheet(button: button),
  );
}

class _ButtonEditorSheet extends ConsumerStatefulWidget {
  const _ButtonEditorSheet({required this.button});

  final RemoteButton button;

  @override
  ConsumerState<_ButtonEditorSheet> createState() => _ButtonEditorSheetState();
}

class _ButtonEditorSheetState extends ConsumerState<_ButtonEditorSheet> {
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
    final imagePaths = ref.watch(customImagePathsProvider);
    final glyph = resolveButton(
      _button,
      imagePaths: imagePaths,
      labelFor: context.l10n.remoteKeyLabel,
    ).glyph;
    final iconLeading = switch (glyph) {
      IconGlyph(:final icon) => Icon(icon),
      ImageGlyph(:final path) => SizedBox(
        width: 40,
        height: 40,
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
        ),
      ),
      TextGlyph() => const Icon(Icons.text_fields),
    };

    return ListView(
      shrinkWrap: true,
      children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                context.l10n.buttonEditorTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: Icon(defaultIconFor(_action)),
              title: Text(context.l10n.buttonEditorActionLabel),
              subtitle: Text(context.l10n.remoteKeyLabel(_action)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _editAction,
            ),
            ListTile(
              leading: iconLeading,
              title: Text(context.l10n.buttonEditorIconLabel),
              subtitle: Text(_appearanceDescription(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _editIcon,
            ),
            const Divider(height: 16),
            SwitchListTile(
              title: Text(context.l10n.buttonEditorShowLabel),
              subtitle: Text(
                _showLabel
                    ? context.l10n.buttonEditorShowLabelOn
                    : context.l10n.buttonEditorShowLabelOff,
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
                  labelText: context.l10n.buttonEditorLabelField,
                  border: const OutlineInputBorder(),
                  hintText: context.l10n.remoteKeyLabel(_action),
                  helperText: _showLabel && _labelController.text.isEmpty
                      ? context.l10n.buttonEditorLabelHelper(
                          context.l10n.remoteKeyLabel(_action),
                        )
                      : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(_button),
                child: Text(context.l10n.commonDone),
              ),
            ),
      ],
    );
  }

  /// A short, localized description of the chosen appearance kind.
  String _appearanceDescription(BuildContext context) => switch (_appearance) {
    DefaultLook() => context.l10n.appearanceDefault,
    TextOnly() => context.l10n.appearanceTextOnly,
    // iconName degrades an unknown id to 'Custom icon' on its own.
    BuiltInIcon(:final iconId) => context.l10n.iconName(iconId),
    PackIcon() => context.l10n.appearancePackIcon,
    CustomImage() => context.l10n.appearanceCustomImage,
  };
}
