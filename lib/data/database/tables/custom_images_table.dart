import 'package:drift/drift.dart';

/// Tracks user-uploaded button images (design doc §6.2 / §7).
///
/// The image *bytes* are not stored here — they live as files in the app
/// documents directory (`remote_images/<file_name>`). This table holds only
/// the id → file-name mapping plus a timestamp, which is enough to list the
/// images and to drive the orphan sweep that deletes unreferenced files.
class CustomImagesTable extends Table {
  /// Stable image id (a uuid). Referenced by `CustomImage` button appearances.
  TextColumn get id => text()();

  /// Name of the backing file inside the `remote_images/` directory.
  TextColumn get fileName => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
