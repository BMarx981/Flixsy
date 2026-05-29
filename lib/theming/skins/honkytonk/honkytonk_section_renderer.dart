import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:flixsy/data/models/layout/layout_block.dart';
import 'package:flixsy/data/models/layout/remote_button.dart';
import 'package:flixsy/shared/widgets/pointer_aware_star_dpad.dart';
import 'package:flixsy/theming/icons/remote_key_l10n.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flixsy/theming/skin_tokens.dart';
import 'package:flixsy/theming/standard/button_presentation.dart';
import 'package:flixsy/theming/standard/remote_image_scope.dart';
import 'package:flixsy/theming/standard/section_renderer.dart';
import 'package:flixsy/theming/skins/honkytonk/honkytonk_pulse_scope.dart';
import 'package:flixsy/theming/skins/honkytonk/honkytonk_theme.dart';

/// Renders the `Honkytonk` skin's blocks: mahogany panels with a hot-pink
/// neon rim that breathes with the shared pulse, picking up the stage sign's
/// warmth on the remote surface.
class HonkytonkSectionRenderer implements SectionRenderer {
  const HonkytonkSectionRenderer();

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
        Padding(
          padding: EdgeInsets.all(gap / 2),
          child: PointerAwareStarDpad(
            size: 235,
            onUp: () => onKey(block.up.action),
            onDown: () => onKey(block.down.action),
            onLeft: () => onKey(block.left.action),
            onRight: () => onKey(block.right.action),
            onOk: () => onKey(block.ok.action),
            onScrollUp: () => onKey(RemoteKey.up),
            onScrollDown: () => onKey(RemoteKey.down),
            onScrollLeft: () => onKey(RemoteKey.left),
            onScrollRight: () => onKey(RemoteKey.right),
          ),
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
      child: _HonkytonkButton(
        presentation: presentation,
        onPressed: () => onKey(button.action),
        compact: compact,
      ),
    );
  }
}

class _HonkytonkButton extends StatelessWidget {
  const _HonkytonkButton({
    required this.presentation,
    required this.onPressed,
    this.compact = false,
  });

  final ButtonPresentation presentation;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pulse = HonkytonkPulseScope.of(context);
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = pulse.value;
        return Container(
          decoration: BoxDecoration(
            color: HonkytonkTheme.alpha(
              HonkytonkTheme.mahogany,
              0.70 + 0.04 * t,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: HonkytonkTheme.alpha(
                HonkytonkTheme.neon,
                0.30 + 0.22 * t,
              ),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: HonkytonkTheme.alpha(
                  HonkytonkTheme.neon,
                  0.10 + 0.14 * t,
                ),
                blurRadius: 12 + 10 * t,
                spreadRadius: 0.4,
              ),
              BoxShadow(
                color: HonkytonkTheme.alpha(
                  HonkytonkTheme.bulb,
                  0.05 + 0.05 * t,
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
          splashColor: HonkytonkTheme.alpha(HonkytonkTheme.neon, 0.30),
          highlightColor: HonkytonkTheme.alpha(HonkytonkTheme.bourbon, 0.14),
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            alignment: Alignment.center,
            padding: compact
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: HonkytonkTheme.cream),
              child: IconTheme.merge(
                data: const IconThemeData(color: HonkytonkTheme.cream),
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
    final scaler = MediaQuery.textScalerOf(context);
    final iconSize = scaler.scale(compact ? 18.0 : 24.0);
    final imageSide = scaler.scale(compact ? 20.0 : 28.0);
    final mark = switch (glyph) {
      IconGlyph(:final icon) => Icon(icon, size: iconSize),
      ImageGlyph(:final path) => Image.file(
        File(path),
        width: imageSide,
        height: imageSide,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) =>
            Icon(Icons.broken_image_outlined, size: iconSize),
      ),
      TextGlyph(:final text) => Text(text),
    };

    return Semantics(label: presentation.semanticLabel, child: mark);
  }
}
