import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/extensions/l10n_extensions.dart';
import '../../../data/models/layout/layout_block.dart';
import '../../../data/models/layout/remote_button.dart';
import '../../icons/remote_key_l10n.dart';
import '../../skin_tokens.dart';
import '../../standard/button_presentation.dart';
import '../../standard/remote_image_scope.dart';
import '../../standard/section_renderer.dart';
import 'cityscape_pulse_scope.dart';
import 'cityscape_theme.dart';

/// Renders the `Cityscape` skin's blocks: midnight-blue panels with a cool
/// cyan window-glow rim that breathes with the shared pulse, echoing the lit
/// windows in the skyline behind.
class CityscapeSectionRenderer implements SectionRenderer {
  const CityscapeSectionRenderer();

  static const double _emptyCellSide = 60;

  @override
  Widget buildDpad(
    BuildContext context,
    DpadBlock block,
    KeyPressHandler onKey,
  ) {
    final gap = SkinTokens.of(context).buttonGap;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _button(context, block.volumeUp, onKey, gap, compact: true),
            _button(context, block.volumeDown, onKey, gap, compact: true),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _button(context, block.up, onKey, gap),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _button(context, block.left, onKey, gap),
                _button(context, block.ok, onKey, gap),
                _button(context, block.right, onKey, gap),
              ],
            ),
            _button(context, block.down, onKey, gap),
          ],
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _button(context, block.channelUp, onKey, gap, compact: true),
            _button(context, block.channelDown, onKey, gap, compact: true),
          ],
        ),
      ],
    );
  }

  @override
  Widget buildButtonRow(
    BuildContext context,
    ButtonRowBlock block,
    KeyPressHandler onKey,
  ) {
    final gap = SkinTokens.of(context).buttonGap;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final button in block.buttons)
          _button(context, button, onKey, gap),
      ],
    );
  }

  @override
  Widget buildVolume(
    BuildContext context,
    VolumeBlock block,
    KeyPressHandler onKey,
  ) {
    final gap = SkinTokens.of(context).buttonGap;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(context, block.volumeDown, onKey, gap),
        _button(context, block.mute, onKey, gap),
        _button(context, block.volumeUp, onKey, gap),
      ],
    );
  }

  @override
  Widget buildGrid(
    BuildContext context,
    GridBlock block,
    KeyPressHandler onKey,
  ) {
    final gap = SkinTokens.of(context).buttonGap;
    final columns = math.max(1, block.columns);
    final rows = <Widget>[];
    for (var start = 0; start < block.cells.length; start += columns) {
      final end = math.min(start + columns, block.cells.length);
      rows.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final cell in block.cells.sublist(start, end))
              cell == null
                  ? const SizedBox.square(dimension: _emptyCellSide)
                  : _button(context, cell, onKey, gap),
          ],
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  @override
  Widget buildSpacer(BuildContext context, SpacerBlock block) =>
      SizedBox(height: block.height);

  Widget _button(
    BuildContext context,
    RemoteButton button,
    KeyPressHandler onKey,
    double gap, {
    bool compact = false,
  }) {
    final presentation = resolveButton(
      button,
      imagePaths: RemoteImageScope.of(context),
      labelFor: context.l10n.remoteKeyLabel,
    );
    return Padding(
      padding: EdgeInsets.all(gap / 2),
      child: _CityscapeButton(
        presentation: presentation,
        onPressed: () => onKey(button.action),
        compact: compact,
      ),
    );
  }
}

class _CityscapeButton extends StatelessWidget {
  const _CityscapeButton({
    required this.presentation,
    required this.onPressed,
    this.compact = false,
  });

  final ButtonPresentation presentation;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pulse = CityscapePulseScope.of(context);
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = pulse.value;
        return Container(
          decoration: BoxDecoration(
            color: CityscapeTheme.alpha(
              CityscapeTheme.midnight,
              0.72 + 0.04 * t,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: CityscapeTheme.alpha(
                CityscapeTheme.neon,
                0.28 + 0.22 * t,
              ),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: CityscapeTheme.alpha(
                  CityscapeTheme.neon,
                  0.10 + 0.14 * t,
                ),
                blurRadius: 12 + 10 * t,
                spreadRadius: 0.4,
              ),
              BoxShadow(
                color: CityscapeTheme.alpha(
                  CityscapeTheme.window,
                  0.04 + 0.05 * t,
                ),
                blurRadius: 18,
                spreadRadius: -2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: CityscapeTheme.alpha(CityscapeTheme.neon, 0.30),
          highlightColor: CityscapeTheme.alpha(CityscapeTheme.window, 0.14),
          onTap: onPressed,
          child: Padding(
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: CityscapeTheme.ice),
              child: IconTheme.merge(
                data: const IconThemeData(color: CityscapeTheme.ice),
                child: _ButtonContent(
                  presentation: presentation,
                  compact: compact,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.presentation, this.compact = false});

  final ButtonPresentation presentation;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final glyph = presentation.glyph;
    final iconSize = compact ? 18.0 : 24.0;
    final imageSide = compact ? 20.0 : 28.0;
    final mark = switch (glyph) {
      IconGlyph(:final icon) => Icon(icon, size: iconSize),
      ImageGlyph(:final path) => Image.file(
        File(path),
        width: imageSide,
        height: imageSide,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Icon(Icons.broken_image_outlined, size: iconSize),
      ),
      TextGlyph(:final text) => Text(text),
    };

    return Semantics(label: presentation.semanticLabel, child: mark);
  }
}
