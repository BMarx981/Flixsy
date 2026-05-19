/// Resolves a [RemoteButton]'s appearance into the parts a standard renderer
/// paints.
///
/// Resolution is **total** (`docs/custom_layouts_design.md` §4.4): any
/// unresolvable icon — unknown id, missing pack, or a Phase-6 [CustomImage]
/// with no image store yet — degrades to the action's catalogue default. A
/// custom layout can therefore be ugly but never broken.
library;

import 'package:flutter/widgets.dart';

import '../../data/models/layout/button_appearance.dart';
import '../../data/models/layout/remote_button.dart';
import '../icons/icon_catalog.dart';

/// What a standard renderer paints as a button's primary mark.
sealed class ButtonGlyph {
  const ButtonGlyph();
}

/// A catalogue icon — the mark for every appearance except [TextOnly].
final class IconGlyph extends ButtonGlyph {
  const IconGlyph(this.icon);

  final IconData icon;
}

/// A short text mark — the whole content of a [TextOnly] button.
final class TextGlyph extends ButtonGlyph {
  const TextGlyph(this.text);

  final String text;
}

/// A button's appearance resolved into the parts a renderer paints.
@immutable
class ButtonPresentation {
  const ButtonPresentation({
    required this.glyph,
    required this.caption,
    required this.semanticLabel,
  });

  /// The primary mark — an [IconGlyph], or a [TextGlyph] for a text-only
  /// button.
  final ButtonGlyph glyph;

  /// The label shown beneath the glyph, or `null` to show none — either the
  /// user hid it (`labelOverride == ''`) or the glyph already is the text.
  final String? caption;

  /// The accessibility label. Always non-empty, even when [caption] is hidden.
  final String semanticLabel;
}

/// Resolves [button] into the icon/text + caption a standard renderer paints.
ButtonPresentation resolveButton(RemoteButton button) {
  final appearance = button.appearance;
  final keyLabel = defaultLabel(button.action);
  final override = appearance.labelOverride;

  // labelOverride: null = use the key default; '' = hide; else the text.
  final caption = override == '' ? null : (override ?? keyLabel);
  // Semantics must never be empty — fall back to the key default.
  final semanticLabel = (override != null && override.isNotEmpty)
      ? override
      : keyLabel;

  if (appearance is TextOnly) {
    // The text itself is the glyph, so there is no separate caption.
    return ButtonPresentation(
      glyph: TextGlyph(override ?? keyLabel),
      caption: null,
      semanticLabel: semanticLabel,
    );
  }

  final icon = _resolveIcon(button) ?? defaultIconFor(button.action);
  return ButtonPresentation(
    glyph: IconGlyph(icon),
    caption: caption,
    semanticLabel: semanticLabel,
  );
}

/// The glyph for an icon-kind appearance, or `null` when it cannot be
/// resolved — the caller then falls back to the action's default icon.
IconData? _resolveIcon(RemoteButton button) {
  return switch (button.appearance) {
    DefaultLook() => defaultIconFor(button.action),
    BuiltInIcon(:final iconId) => resolvePackIcon(standardPack.id, iconId),
    PackIcon(:final packId, :final iconId) => resolvePackIcon(packId, iconId),
    // Phase 6 introduces the image store; until then a custom image degrades.
    CustomImage() => null,
    // Handled before this switch — listed so the switch stays exhaustive.
    TextOnly() => null,
  };
}
