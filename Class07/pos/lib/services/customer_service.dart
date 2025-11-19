import 'package:sqflite/sqflite.dart';
import '../models/customer_model.dart';
import 'database_service.dart';

class CustomerService {
  Future<Database> get _db async => await DatabaseService.database;

  Future<List<CustomerModel>> getAll({String? search}) async {
    final db = await _db;
    List<Map<String, dynamic>> rows;
    if (search != null && search.trim().isNotEmpty) {
      final q = '%${search.trim().toLowerCase()}%';
      rows = await db.query(
        'customers',
        where: 'LOWER(name) LIKE ? OR LOWER(phone) LIKE ?',
        whereArgs: [q, q],
        orderBy: 'name COLLATE NOCASE ASC',
      );
    } else {
      rows = await db.query('customers', orderBy: 'name COLLATE NOCASE ASC');
    }
    return rows.map(CustomerModel.fromMap).toList();
  }

  Future<int> insert(CustomerModel c) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final data = c.toMap()
      ..remove('id')
      ..['balance'] = 0.0 // always start with 0
      ..['createdAt'] = now
      ..['updatedAt'] = now;
    return db.insert('customers', data);
  }

  Future<int> update(CustomerModel c) async {
    if (c.id == null) return 0;
    final db = await _db;
    final data = c.toMap()..['updatedAt'] = DateTime.now().toIso8601String();
    return db.update('customers', data, where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}
