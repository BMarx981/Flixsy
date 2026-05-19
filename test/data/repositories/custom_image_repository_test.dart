import 'dart:io';

import 'package:drift/native.dart';
import 'package:flixsy/data/database/app_database.dart';
import 'package:flixsy/data/repositories/custom_image_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('flixsy_img_test');
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  /// Writes [bytes] to a source file and wraps it as a picked image.
  Future<XFile> fakePick(List<int> bytes) async {
    final source = File('${tempDir.path}/picked.png');
    await source.writeAsBytes(bytes);
    return XFile(source.path);
  }

  CustomImageRepository repo({ImagePickFunction? pickImage}) {
    return CustomImageRepository(
      db,
      documentsDirectory: () async => tempDir,
      pickImage: pickImage ?? () => fakePick(const [1, 2, 3]),
    );
  }

  test('importImage copies the file into storage and records a row', () async {
    final image = await repo().importImage();

    expect(image, isNotNull);
    expect(File(image!.path).existsSync(), isTrue);
    expect(await File(image.path).readAsBytes(), const [1, 2, 3]);
    // The file lives under the managed remote_images/ directory.
    expect(image.path, contains('remote_images'));

    final rows = await db.customImagesDao.getAll();
    expect(rows, hasLength(1));
    expect(rows.single.id, image.id);
  });

  test('importImage returns null when the picker is cancelled', () async {
    final image = await repo(pickImage: () async => null).importImage();

    expect(image, isNull);
    expect(await db.customImagesDao.getAll(), isEmpty);
  });

  test('watchImages emits stored images with absolute file paths', () async {
    final repository = repo();
    final image = await repository.importImage();

    final images = await repository.watchImages().first;
    expect(images, hasLength(1));
    expect(images.single.id, image!.id);
    expect(images.single.path, image.path);
  });

  test('sweepOrphans deletes unreferenced images and keeps the rest', () async {
    final repository = repo();
    final keep = await repository.importImage();
    final drop = await repository.importImage();
    expect(await db.customImagesDao.getAll(), hasLength(2));

    await repository.sweepOrphans({keep!.id});

    final remaining = await db.customImagesDao.getAll();
    expect(remaining, hasLength(1));
    expect(remaining.single.id, keep.id);
    expect(File(keep.path).existsSync(), isTrue);
    expect(File(drop!.path).existsSync(), isFalse);
  });

  test('sweepOrphans with no referenced ids clears every image', () async {
    final repository = repo();
    await repository.importImage();
    await repository.importImage();

    await repository.sweepOrphans(const {});

    expect(await db.customImagesDao.getAll(), isEmpty);
  });
}
