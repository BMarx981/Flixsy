import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/custom_images_table.dart';

part 'custom_images_dao.g.dart';

/// Data access for user-uploaded button images. Stays behind
/// `CustomImageRepository` — per project rules, providers and widgets never
/// touch the DAO directly.
@DriftAccessor(tables: [CustomImagesTable])
class CustomImagesDao extends DatabaseAccessor<AppDatabase>
    with _$CustomImagesDaoMixin {
  CustomImagesDao(super.db);

  /// Watches every stored image, most recently added first.
  Stream<List<CustomImagesTableData>> watchAll() {
    return (select(customImagesTable)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  /// Every stored image, most recently added first.
  Future<List<CustomImagesTableData>> getAll() {
    return (select(customImagesTable)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<void> insertImage(CustomImagesTableCompanion entry) {
    return into(customImagesTable).insert(entry);
  }

  Future<void> deleteById(String id) {
    return (delete(customImagesTable)..where((t) => t.id.equals(id))).go();
  }
}
