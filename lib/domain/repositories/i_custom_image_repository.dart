import 'package:flixsy/data/models/stored_image.dart';

/// Access to user-uploaded button images — the only entry point to image
/// persistence; the DAO and the file system stay hidden behind it (design
/// doc §6.2 / §7).
abstract interface class ICustomImageRepository {
  /// Watches every stored image, most recently added first. Each [StoredImage]
  /// carries the absolute path to its backing file.
  Stream<List<StoredImage>> watchImages();

  /// Imports an image the user picks from their gallery: it is downscaled to
  /// bound storage, copied into app storage, and recorded. Returns the new
  /// image, or `null` if the user cancels the picker.
  Future<StoredImage?> importImage();

  /// Deletes every stored image whose id is absent from [referencedIds] —
  /// removing both the database row and the file.
  ///
  /// Run after layouts change so images no button uses are not kept forever
  /// (the orphan sweep, design doc §6.2).
  Future<void> sweepOrphans(Set<String> referencedIds);
}
