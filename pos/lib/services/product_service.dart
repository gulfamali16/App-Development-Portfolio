import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';
import 'database_service.dart';

class ProductService {
  // ✅ Correct call to the static getter on DatabaseService
  Future<Database> get _db async => await DatabaseService.database;

  // All products (by name)
  Future<List<ProductModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('products', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<ProductModel?> getById(int id) async {
    final db = await _db;
    final rows = await db.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return ProductModel.fromMap(rows.first);
  }

  // Search by name or category
  Future<List<ProductModel>> search(String query) async {
    final db = await _db;
    final q = '%${query.trim().toLowerCase()}%';
    final rows = await db.query(
      'products',
      where: 'LOWER(name) LIKE ? OR LOWER(category) LIKE ?',
      whereArgs: [q, q],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(ProductModel.fromMap).toList();
  }

  // Insert
  Future<int> insert(ProductModel p) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final data = Map<String, dynamic>.from(p.toMap())
      ..remove('id')
      ..['createdAt'] = now
      ..['updatedAt'] = now;
    return db.insert('products', data);
  }

  // Update
  Future<int> update(ProductModel p) async {
    if (p.id == null) return 0;
    final db = await _db;
    final data = Map<String, dynamic>.from(p.toMap())
      ..['updatedAt'] = DateTime.now().toIso8601String();
    return db.update('products', data, where: 'id = ?', whereArgs: [p.id]);
  }

  // Delete
  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // Count low stock items
  Future<int> countLowStock({int threshold = 10}) async {
    final db = await _db;
    final row = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM products WHERE stock < ?', [threshold]
    );
    return (row.first['c'] as num).toInt();
  }

  // Optional: seed items
  Future<void> insertMany(List<ProductModel> items) async {
    final db = await _db;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final p in items) {
      final m = Map<String, dynamic>.from(p.toMap())
        ..remove('id')
        ..['createdAt'] = now
        ..['updatedAt'] = now;
      batch.insert('products', m);
    }
    await batch.commit(noResult: true);
  }
}
