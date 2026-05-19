/// How a [RemoteButton] *looks* — the appearance axis of a button.
///
/// Per `docs/custom_layouts_design.md` §3, appearance can never change what a
/// button does, so a custom layout can be ugly but never broken.
///
/// Deserialization is **total**: [ButtonAppearance.fromJson] degrades any
/// unknown or malformed payload to [DefaultLook] rather than throwing, so a
/// layout written by a newer build still renders on an older one.
library;

sealed class ButtonAppearance {
  const ButtonAppearance({this.labelOverride});

  /// `null` = use the key's default label; `''` = hide the label entirely;
  /// any other value = show that text.
  final String? labelOverride;

  Map<String, Object?> toJson();

  factory ButtonAppearance.fromJson(Map<String, Object?> json) {
    final rawLabel = json['labelOverride'];
    final labelOverride = rawLabel is String ? rawLabel : null;
    final kind = json['kind'];
    final iconId = json['iconId'];
    final packId = json['packId'];
    final imageId = json['imageId'];

    if (kind == 'textOnly') {
      return TextOnly(labelOverride: labelOverride);
    }
    if (kind == 'builtInIcon' && iconId is String) {
      return BuiltInIcon(iconId: iconId, labelOverride: labelOverride);
    }
    if (kind == 'packIcon' && packId is String && iconId is String) {
      return PackIcon(
        packId: packId,
        iconId: iconId,
        labelOverride: labelOverride,
      );
    }
    if (kind == 'customImage' && imageId is String) {
      return CustomImage(imageId: imageId, labelOverride: labelOverride);
    }
    // 'default', an unknown kind, or an icon/image entry missing its id all
    // degrade to the catalogue default — never a thrown exception.
    return DefaultLook(labelOverride: labelOverride);
  }
}

/// Encodes the shared [ButtonAppearance.labelOverride] alongside a [kind] tag.
Map<String, Object?> _baseJson(String kind, String? labelOverride) => {
  'kind': kind,
  'labelOverride': ?labelOverride,
};

/// The action's catalogue default icon + label.
final class DefaultLook extends ButtonAppearance {
  const DefaultLook({super.labelOverride});

  @override
  Map<String, Object?> toJson() => _baseJson('default', labelOverride);
}

/// An icon from the curated built-in `Standard` pack.
///
/// [iconId] is resolved against the icon catalogue introduced in Phase 5;
/// until then it renders as a [DefaultLook].
final class BuiltInIcon extends ButtonAppearance {
  const BuiltInIcon({required this.iconId, super.labelOverride});

  final String iconId;

  @override
  Map<String, Object?> toJson() => {
    ..._baseJson('builtInIcon', labelOverride),
    'iconId': iconId,
  };
}

/// An icon from a branded/partner pack (Phase 7).
final class PackIcon extends ButtonAppearance {
  const PackIcon({
    required this.packId,
    required this.iconId,
    super.labelOverride,
  });

  final String packId;
  final String iconId;

  @override
  Map<String, Object?> toJson() => {
    ..._baseJson('packIcon', labelOverride),
    'packId': packId,
    'iconId': iconId,
  };
}

/// A user-uploaded image, referenced by id into the custom-image store
/// introduced in Phase 6.
final class CustomImage extends ButtonAppearance {
  const CustomImage({required this.imageId, super.labelOverride});

  final String imageId;

  @override
  Map<String, Object?> toJson() => {
    ..._baseJson('customImage', labelOverride),
    'imageId': imageId,
  };
}

/// A button with no glyph — just its label text.
final class TextOnly extends ButtonAppearance {
  const TextOnly({super.labelOverride});

  @override
  Map<String, Object?> toJson() => _baseJson('textOnly', labelOverride);
}
