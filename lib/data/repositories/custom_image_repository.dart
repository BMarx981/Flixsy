import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/i_custom_image_repository.dart';
import '../database/app_database.dart';
import '../models/stored_image.dart';

/// Picks one image from the device. Injected so tests supply a fake instead
/// of touching the platform image picker.
typedef ImagePickFunction = Future<XFile?> Function();

/// File-backed [ICustomImageRepository].
///
/// Image bytes are stored as files under `remote_images/` in the app
/// documents directory; the `custom_images` table holds only the id → file
/// mapping. Imported images are downscaled to bound storage (design §6.2).
class CustomImageRepository implements ICustomImageRepository {
  CustomImageRepository(
    this._db, {
    Future<Directory> Function()? documentsDirectory,
    ImagePickFunction? pickImage,
  }) : _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory,
       _pickImage = pickImage ?? _pickFromGallery;

  final AppDatabase _db;
  final Future<Directory> Function() _documentsDirectory;
  final ImagePickFunction _pickImage;

  static final Uuid _uuid = Uuid();

  /// Longest edge, in pixels, an imported image is downscaled to.
  static const double _maxDimension = 256;

  /// Subdirectory of the app documents directory that holds image files.
  static const String _imagesDirName = 'remote_images';

  Directory? _cachedDir;

  /// The `remote_images/` directory, created on first use.
  Future<Directory> _imagesDir() async {
    final cached = _cachedDir;
    if (cached != null) return cached;
    final docs = await _documentsDirectory();
    final dir = Directory(p.join(docs.path, _imagesDirName));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return _cachedDir = dir;
  }

  static Future<XFile?> _pickFromGallery() {
    return ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxDimension,
      maxHeight: _maxDimension,
      imageQuality: 85,
    );
  }

  @override
  Stream<List<StoredImage>> watchImages() {
    // Resolve the directory once, then join each stored row to its file path.
    return Stream.fromFuture(_imagesDir()).asyncExpand((dir) {
      return _db.customImagesDao.watchAll().map(
        (rows) => [
          for (final row in rows)
            StoredImage(
              id: row.id,
              path: p.join(dir.path, row.fileName),
              createdAt: row.createdAt,
            ),
        ],
      );
    });
  }

  @override
  Future<StoredImage?> importImage() async {
    final picked = await _pickImage();
    if (picked == null) return null;

    final id = _uuid.v4();
    final extension = p.extension(picked.path);
    final fileName = '$id${extension.isEmpty ? '.png' : extension}';
    final dir = await _imagesDir();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(await picked.readAsBytes());

    final now = DateTime.now();
    await _db.customImagesDao.insertImage(
      CustomImagesTableCompanion.insert(
        id: id,
        fileName: fileName,
        createdAt: now,
      ),
    );
    return StoredImage(id: id, path: file.path, createdAt: now);
  }

  @override
  Future<void> sweepOrphans(Set<String> referencedIds) async {
    final dir = await _imagesDir();
    for (final row in await _db.customImagesDao.getAll()) {
      if (referencedIds.contains(row.id)) continue;
      final file = File(p.join(dir.path, row.fileName));
      if (file.existsSync()) {
        try {
          await file.delete();
        } on FileSystemException {
          // Best-effort — a file we cannot delete is left for the next sweep.
        }
      }
      await _db.customImagesDao.deleteById(row.id);
    }
  }
}
