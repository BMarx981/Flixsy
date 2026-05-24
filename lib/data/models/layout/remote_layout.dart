import 'package:flixsy/data/models/layout/button_appearance.dart';
import 'package:flixsy/data/models/layout/layout_block.dart';

/// A complete remote layout — the *user-authored* axis of the three-axis
/// model (capability / layout / skin); see `docs/custom_layouts_design.md`.
///
/// A layout is data: an ordered list of [blocks] that any standard skin can
/// render. It round-trips through JSON so it can be stored in Drift and
/// edited.
class RemoteLayout {
  const RemoteLayout({
    required this.id,
    required this.name,
    required this.blocks,
    this.isTemplate = false,
  });

  /// Stable id. Built-in templates use the reserved `builtin:` prefix.
  final String id;

  final String name;

  /// `true` for read-only built-in templates; editing one duplicates it
  /// into a writable layout.
  final bool isTemplate;

  /// The ordered sections of the remote.
  final List<LayoutBlock> blocks;

  /// The ids of every custom image this layout's buttons reference.
  ///
  /// Drives the orphan sweep (design doc §6.2): an image referenced by no
  /// layout is unreachable and can be deleted.
  Iterable<String> get referencedImageIds sync* {
    for (final block in blocks) {
      for (final button in block.buttons) {
        final appearance = button?.appearance;
        if (appearance is CustomImage) yield appearance.imageId;
      }
    }
  }

  /// Returns a copy with the given fields replaced. Used by the layout
  /// editor to apply edits to its immutable draft.
  RemoteLayout copyWith({
    String? id,
    String? name,
    bool? isTemplate,
    List<LayoutBlock>? blocks,
  }) {
    return RemoteLayout(
      id: id ?? this.id,
      name: name ?? this.name,
      isTemplate: isTemplate ?? this.isTemplate,
      blocks: blocks ?? this.blocks,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'isTemplate': isTemplate,
    'blocks': [for (final block in blocks) block.toJson()],
  };

  /// Parses a layout, tolerating malformed input: unreadable or
  /// unrecognised blocks are dropped so a layout never crashes the app.
  factory RemoteLayout.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    final isTemplate = json['isTemplate'];
    final rawBlocks = json['blocks'];

    final blocks = <LayoutBlock>[];
    if (rawBlocks is List) {
      for (final entry in rawBlocks) {
        if (entry is Map) {
          final block = LayoutBlock.fromJson(entry.cast<String, Object?>());
          if (block != null) blocks.add(block);
        }
      }
    }

    return RemoteLayout(
      id: id is String ? id : '',
      name: name is String ? name : 'Untitled',
      isTemplate: isTemplate is bool ? isTemplate : false,
      blocks: blocks,
    );
  }
}
