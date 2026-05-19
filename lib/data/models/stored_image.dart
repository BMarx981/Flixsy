/// A user-uploaded button image, resolved to its on-disk location.
///
/// The image bytes live as a file in the app documents directory; this model
/// pairs the stable [id] (referenced by `CustomImage` button appearances) with
/// the absolute file [path] a renderer can hand to `Image.file`.
///
/// Pure Dart, no Flutter import — it crosses the `domain/` repository boundary.
class StoredImage {
  const StoredImage({
    required this.id,
    required this.path,
    required this.createdAt,
  });

  /// Stable image id (a uuid).
  final String id;

  /// Absolute path to the backing image file.
  final String path;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      other is StoredImage &&
      other.id == id &&
      other.path == path &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, path, createdAt);
}
