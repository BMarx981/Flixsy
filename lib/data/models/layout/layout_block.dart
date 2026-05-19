import '../../../theming/remote_key.dart';
import 'remote_button.dart';

/// One section of a [RemoteLayout]. A layout is an ordered list of blocks;
/// each block type renders itself responsively, so a layout is valid at any
/// screen size (see `docs/custom_layouts_design.md` §4.3).
///
/// Adding a block type later is one new subclass here plus one renderer
/// method per standard skin — no change to storage or the editor framework.
sealed class LayoutBlock {
  const LayoutBlock();

  Map<String, Object?> toJson();

  /// The block's buttons, in canonical order. A `null` entry is an empty
  /// slot — only [GridBlock] has them; [SpacerBlock] has none.
  List<RemoteButton?> get buttons;

  /// A copy of this block with the button at [index] replaced. An
  /// out-of-range [index] (or a [SpacerBlock], which has no buttons) returns
  /// the block unchanged.
  LayoutBlock withButtonAt(int index, RemoteButton button);

  /// Parses a block, or `null` for an unrecognised `type`.
  ///
  /// Dropping unknown blocks (rather than throwing) lets a layout written by
  /// a newer build still load on an older one.
  static LayoutBlock? fromJson(Map<String, Object?> json) {
    return switch (json['type']) {
      'dpad' => DpadBlock.fromJson(json),
      'buttonRow' => ButtonRowBlock.fromJson(json),
      'volume' => VolumeBlock.fromJson(json),
      'grid' => GridBlock.fromJson(json),
      'spacer' => SpacerBlock.fromJson(json),
      _ => null,
    };
  }
}

/// A five-button directional cross. The cross arrangement is fixed; only the
/// buttons' actions and appearance vary.
final class DpadBlock extends LayoutBlock {
  const DpadBlock({
    required this.up,
    required this.down,
    required this.left,
    required this.right,
    required this.ok,
  });

  final RemoteButton up;
  final RemoteButton down;
  final RemoteButton left;
  final RemoteButton right;
  final RemoteButton ok;

  @override
  Map<String, Object?> toJson() => {
    'type': 'dpad',
    'up': up.toJson(),
    'down': down.toJson(),
    'left': left.toJson(),
    'right': right.toJson(),
    'ok': ok.toJson(),
  };

  factory DpadBlock.fromJson(Map<String, Object?> json) => DpadBlock(
    up: _slot(json['up'], RemoteKey.up),
    down: _slot(json['down'], RemoteKey.down),
    left: _slot(json['left'], RemoteKey.left),
    right: _slot(json['right'], RemoteKey.right),
    ok: _slot(json['ok'], RemoteKey.ok),
  );

  @override
  List<RemoteButton?> get buttons => [up, down, left, right, ok];

  @override
  DpadBlock withButtonAt(int index, RemoteButton button) {
    if (index < 0 || index > 4) return this;
    final next = <RemoteButton>[up, down, left, right, ok];
    next[index] = button;
    return DpadBlock(
      up: next[0],
      down: next[1],
      left: next[2],
      right: next[3],
      ok: next[4],
    );
  }
}

/// An evenly spaced row of 1–5 buttons.
final class ButtonRowBlock extends LayoutBlock {
  const ButtonRowBlock({required this.buttons});

  @override
  final List<RemoteButton> buttons;

  @override
  Map<String, Object?> toJson() => {
    'type': 'buttonRow',
    'buttons': [for (final button in buttons) button.toJson()],
  };

  factory ButtonRowBlock.fromJson(Map<String, Object?> json) =>
      ButtonRowBlock(buttons: _buttonList(json['buttons']));

  @override
  ButtonRowBlock withButtonAt(int index, RemoteButton button) {
    if (index < 0 || index >= buttons.length) return this;
    final next = [...buttons];
    next[index] = button;
    return ButtonRowBlock(buttons: next);
  }
}

/// A volume rocker: volume-down / mute / volume-up.
final class VolumeBlock extends LayoutBlock {
  const VolumeBlock({
    required this.volumeDown,
    required this.mute,
    required this.volumeUp,
  });

  final RemoteButton volumeDown;
  final RemoteButton mute;
  final RemoteButton volumeUp;

  @override
  Map<String, Object?> toJson() => {
    'type': 'volume',
    'volumeDown': volumeDown.toJson(),
    'mute': mute.toJson(),
    'volumeUp': volumeUp.toJson(),
  };

  factory VolumeBlock.fromJson(Map<String, Object?> json) => VolumeBlock(
    volumeDown: _slot(json['volumeDown'], RemoteKey.volumeDown),
    mute: _slot(json['mute'], RemoteKey.mute),
    volumeUp: _slot(json['volumeUp'], RemoteKey.volumeUp),
  );

  @override
  List<RemoteButton?> get buttons => [volumeDown, mute, volumeUp];

  @override
  VolumeBlock withButtonAt(int index, RemoteButton button) {
    if (index < 0 || index > 2) return this;
    final next = <RemoteButton>[volumeDown, mute, volumeUp];
    next[index] = button;
    return VolumeBlock(volumeDown: next[0], mute: next[1], volumeUp: next[2]);
  }
}

/// A fixed-column grid of buttons. A `null` cell is an intentional empty slot.
final class GridBlock extends LayoutBlock {
  const GridBlock({required this.columns, required this.cells});

  final int columns;
  final List<RemoteButton?> cells;

  @override
  Map<String, Object?> toJson() => {
    'type': 'grid',
    'columns': columns,
    'cells': [for (final cell in cells) cell?.toJson()],
  };

  factory GridBlock.fromJson(Map<String, Object?> json) {
    final rawColumns = json['columns'];
    final rawCells = json['cells'];
    final cells = <RemoteButton?>[];
    if (rawCells is List) {
      for (final entry in rawCells) {
        cells.add(
          entry is Map
              ? RemoteButton.fromJson(entry.cast<String, Object?>())
              : null,
        );
      }
    }
    return GridBlock(
      columns: rawColumns is int && rawColumns > 0 ? rawColumns : 1,
      cells: cells,
    );
  }

  @override
  List<RemoteButton?> get buttons => cells;

  @override
  GridBlock withButtonAt(int index, RemoteButton button) {
    if (index < 0 || index >= cells.length) return this;
    final next = [...cells];
    next[index] = button;
    return GridBlock(columns: columns, cells: next);
  }
}

/// Vertical breathing room between blocks.
final class SpacerBlock extends LayoutBlock {
  const SpacerBlock({required this.height});

  final double height;

  @override
  Map<String, Object?> toJson() => {'type': 'spacer', 'height': height};

  factory SpacerBlock.fromJson(Map<String, Object?> json) {
    final rawHeight = json['height'];
    final height = rawHeight is num ? rawHeight.toDouble() : 0.0;
    return SpacerBlock(height: height < 0 ? 0 : height);
  }

  @override
  List<RemoteButton?> get buttons => const [];

  @override
  SpacerBlock withButtonAt(int index, RemoteButton button) => this;
}

/// Reads one fixed-slot button, falling back to a default button for
/// [fallbackKey] when the stored value is missing or has no resolvable action.
RemoteButton _slot(Object? json, RemoteKey fallbackKey) {
  if (json is Map) {
    final button = RemoteButton.fromJson(json.cast<String, Object?>());
    if (button != null) return button;
  }
  return RemoteButton(action: fallbackKey);
}

/// Reads a button list, silently dropping entries with no resolvable action.
List<RemoteButton> _buttonList(Object? json) {
  if (json is! List) return const [];
  final buttons = <RemoteButton>[];
  for (final entry in json) {
    if (entry is Map) {
      final button = RemoteButton.fromJson(entry.cast<String, Object?>());
      if (button != null) buttons.add(button);
    }
  }
  return buttons;
}
