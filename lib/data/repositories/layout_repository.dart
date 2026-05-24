import 'dart:convert';

import 'package:flixsy/domain/repositories/i_layout_repository.dart';
import 'package:flixsy/data/database/app_database.dart';
import 'package:flixsy/data/models/layout/built_in_layouts.dart';
import 'package:flixsy/data/models/layout/remote_layout.dart';

class LayoutRepository implements ILayoutRepository {
  const LayoutRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<RemoteLayout>> watchAllLayouts() {
    return _db.layoutsDao.watchAll().map(
      (rows) => [...builtInLayouts, ...rows.map(_rowToLayout)],
    );
  }

  @override
  Future<RemoteLayout?> getLayout(String id) async {
    if (id.startsWith(builtInLayoutIdPrefix)) {
      for (final layout in builtInLayouts) {
        if (layout.id == id) return layout;
      }
      return null;
    }
    final row = await _db.layoutsDao.getById(id);
    return row == null ? null : _rowToLayout(row);
  }

  @override
  Future<void> saveLayout(RemoteLayout layout) async {
    // Preserve the original creation time across edits.
    final existing = await _db.layoutsDao.getById(layout.id);
    final now = DateTime.now();
    await _db.layoutsDao.upsert(
      CustomLayoutsTableCompanion.insert(
        id: layout.id,
        name: layout.name,
        blocksJson: jsonEncode([for (final b in layout.blocks) b.toJson()]),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> deleteLayout(String id) {
    return _db.layoutsDao.deleteById(id);
  }

  /// Converts a stored row to a [RemoteLayout]. The row's `id`/`name` columns
  /// are authoritative; only the block tree comes from JSON. A corrupt
  /// `blocksJson` degrades to an empty layout rather than throwing — a layout
  /// must never crash the app (design doc §12).
  RemoteLayout _rowToLayout(CustomLayoutsTableData row) {
    Object? blocks;
    try {
      blocks = jsonDecode(row.blocksJson);
    } on FormatException {
      blocks = null;
    }
    return RemoteLayout.fromJson({
      'id': row.id,
      'name': row.name,
      'isTemplate': false,
      'blocks': blocks,
    });
  }
}
