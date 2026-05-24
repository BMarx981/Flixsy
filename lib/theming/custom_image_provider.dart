import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flixsy/data/models/stored_image.dart';
import 'package:flixsy/shared/providers/app_providers.dart';

/// Every user-uploaded image, most recently added first, streamed from the
/// Drift- and file-backed `CustomImageRepository`.
final customImagesProvider = StreamProvider<List<StoredImage>>((ref) {
  return ref.watch(customImageRepositoryProvider).watchImages();
});

/// Synchronous id → file-path map for the user's images.
///
/// Renderers resolve a `CustomImage` button appearance through this map. An
/// id that is absent — the stream is still loading, or the image was swept —
/// degrades to the action's default icon rather than erroring.
final customImagePathsProvider = Provider<Map<String, String>>((ref) {
  final images = ref.watch(customImagesProvider).valueOrNull ?? const [];
  return {for (final image in images) image.id: image.path};
});

/// Imports custom images and records the analytics event.
///
/// Image import is a user action with a side effect (analytics), so it goes
/// through a controller rather than the repository directly — mirroring
/// `LayoutController`.
class CustomImageController {
  const CustomImageController(this._ref);

  final Ref _ref;

  /// Imports an image the user picks. Returns the new [StoredImage], or `null`
  /// when the picker is cancelled.
  Future<StoredImage?> importImage() async {
    final image = await _ref.read(customImageRepositoryProvider).importImage();
    if (image != null) {
      await _ref.read(analyticsServiceProvider).logCustomImageAdded(image.id);
    }
    return image;
  }
}

final customImageControllerProvider = Provider<CustomImageController>(
  (ref) => CustomImageController(ref),
);
