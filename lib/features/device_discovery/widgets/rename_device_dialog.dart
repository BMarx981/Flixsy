import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:flixsy/data/models/tv_device.dart';
import 'package:flixsy/features/device_discovery/providers/device_display_names_provider.dart';
import 'package:flixsy/shared/providers/app_providers.dart';

/// Opens a glassmorphic rename dialog for [device]. Saving an empty value
/// (or the discovery name) clears the nickname; otherwise the entered value
/// is persisted.
Future<void> showRenameDeviceDialog(
  BuildContext context,
  WidgetRef ref,
  TvDevice device,
) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => _RenameDeviceDialog(device: device),
    transitionBuilder: (_, animation, _, child) {
      final curved = Curves.easeOutCubic.transform(animation.value);
      return Opacity(
        opacity: curved,
        child: Transform.scale(
          scale: 0.92 + 0.08 * curved,
          child: child,
        ),
      );
    },
  );
}

class _RenameDeviceDialog extends ConsumerStatefulWidget {
  const _RenameDeviceDialog({required this.device});

  final TvDevice device;

  @override
  ConsumerState<_RenameDeviceDialog> createState() =>
      _RenameDeviceDialogState();
}

class _RenameDeviceDialogState extends ConsumerState<_RenameDeviceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final nicknames = ref.read(deviceNicknamesProvider).valueOrNull ?? const {};
    _controller = TextEditingController(
      text: nicknames[widget.device.id] ?? widget.device.name,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final entered = _controller.text.trim();
    if (entered.isEmpty || entered == widget.device.name) {
      await prefs.clearDeviceNickname(widget.device.id);
    } else {
      await prefs.setDeviceNickname(widget.device.id, entered);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reset() async {
    await ref
        .read(preferencesRepositoryProvider)
        .clearDeviceNickname(widget.device.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foreground = theme.colorScheme.onSurface;
    final tintTop = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.55);
    final tintBottom = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.30);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.75);

    final nicknames = ref.watch(deviceNicknamesProvider).valueOrNull ?? const {};
    final hasNickname = nicknames.containsKey(widget.device.id);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [tintTop, tintBottom],
                  ),
                  border: Border.all(color: borderColor, width: 1),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.30),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.renameDeviceDialogTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _controller,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _save(),
                          style: TextStyle(color: foreground),
                          decoration: InputDecoration(
                            labelText: l10n.renameDeviceFieldLabel,
                            hintText: widget.device.name,
                            filled: true,
                            fillColor: foreground.withValues(alpha: 0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: foreground.withValues(alpha: 0.15),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: foreground.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (hasNickname)
                              TextButton(
                                onPressed: _reset,
                                child: Text(l10n.renameDeviceResetButton),
                              ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(l10n.renameDeviceCancelButton),
                            ),
                            const SizedBox(width: 4),
                            FilledButton(
                              onPressed: _save,
                              child: Text(l10n.renameDeviceSaveButton),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
