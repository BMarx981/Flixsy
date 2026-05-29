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
import 'package:flixsy/theming/skins/punk/punk_pulse_scope.dart';
import 'package:flixsy/theming/skins/punk/punk_theme.dart';

/// Renders the `Punk` skin's blocks: bottle-black panels with a hot-magenta
/// rim that breathes with the shared pulse and a notched corner to give the
/// chrome a torn, stencil-cut feel against the brick.
class PunkSectionRenderer implements SectionRenderer {
  const PunkSectionRenderer();

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
            _button(context, block.volumeUp, onKey, gap),
            _button(context, block.volumeDown, onKey, gap),
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
            _button(context, block.channelUp, onKey, gap),
            _button(context, block.channelDown, onKey, gap),
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
    double gap,
  ) {
    final presentation = resolveButton(
      button,
      imagePaths: RemoteImageScope.of(context),
      labelFor: context.l10n.remoteKeyLabel,
    );
    return Padding(
      padding: EdgeInsets.all(gap / 2),
      child: _PunkButton(
        presentation: presentation,
        onPressed: () => onKey(button.action),
      ),
    );
  }
}

/// Decoration shape — a rectangle with the top-right corner clipped at 45°,
/// suggesting a torn-poster / stencil-cut look. Used both as the visible
/// border and as the ink-well clip so taps follow the same silhouette.
class _NotchedRectBorder extends OutlinedBorder {
  const _NotchedRectBorder({super.side, this.notch = 12});

  final double notch;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) =>
      _NotchedRectBorder(side: side.scale(t), notch: notch * t);

  @override
  _NotchedRectBorder copyWith({BorderSide? side, double? notch}) =>
      _NotchedRectBorder(side: side ?? this.side, notch: notch ?? this.notch);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _build(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _build(rect);

  Path _build(Rect rect) {
    final n = math.min(notch, math.min(rect.width, rect.height) / 3);
    return Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right - n, rect.top)
      ..lineTo(rect.right, rect.top + n)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(
      getOuterPath(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side.width
        ..color = side.color,
    );
  }
}

class _PunkButton extends StatelessWidget {
  const _PunkButton({required this.presentation, required this.onPressed});

  final ButtonPresentation presentation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final pulse = PunkPulseScope.of(context);
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = pulse.value;
        final shape = _NotchedRectBorder(
          side: BorderSide(
            color: PunkTheme.alpha(PunkTheme.magenta, 0.45 + 0.35 * t),
            width: 1.4,
          ),
        );
        return DecoratedBox(
          decoration: ShapeDecoration(
            color: PunkTheme.alpha(PunkTheme.ink, 0.82 + 0.06 * t),
            shape: shape,
            shadows: [
              BoxShadow(
                color: PunkTheme.alpha(
                  PunkTheme.magenta,
                  0.15 + 0.20 * t,
                ),
                blurRadius: 12 + 12 * t,
                spreadRadius: 0.6,
              ),
              BoxShadow(
                color: PunkTheme.alpha(
                  PunkTheme.acid,
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
        shape: const _NotchedRectBorder(side: BorderSide.none),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashColor: PunkTheme.alpha(PunkTheme.magenta, 0.32),
          highlightColor: PunkTheme.alpha(PunkTheme.acid, 0.12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: PunkTheme.bone,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
              child: IconTheme.merge(
                data: const IconThemeData(color: PunkTheme.bone),
                child: _ButtonContent(presentation: presentation),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.presentation});

  final ButtonPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final glyph = presentation.glyph;
    final scaler = MediaQuery.textScalerOf(context);
    final iconSize = scaler.scale(24.0);
    final imageSide = scaler.scale(28.0);
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
    final caption = presentation.caption;

    final content = caption == null
        ? mark
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              mark,
              const SizedBox(height: 2),
              Text(caption, style: const TextStyle(fontSize: 11)),
            ],
          );

    return Semantics(label: presentation.semanticLabel, child: content);
  }
}
