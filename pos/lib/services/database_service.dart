import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

enum ReportPeriod { day, week, month }

class DatabaseService {
  static Database? _db;
  static const int _dbVersion = 4;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'pos_app.db');
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        // USERS
        await db.execute('''
          CREATE TABLE user(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            pin TEXT,
            password TEXT
          );
        ''');

        // SALES
        await db.execute('''
          CREATE TABLE sales(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customerId INTEGER,
            subtotal REAL NOT NULL,
            tax REAL NOT NULL,
            total REAL NOT NULL,
            paymentMethod TEXT,
            isPaid INTEGER NOT NULL,
            createdAt TEXT
          );
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_sales_created ON sales(createdAt);');

        // SALE ITEMS
        await db.execute('''
          CREATE TABLE sale_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            qty INTEGER NOT NULL,
            price_at_sale REAL NOT NULL,
            FOREIGN KEY(sale_id) REFERENCES sales(id),
            FOREIGN KEY(product_id) REFERENCES products(id)
          );
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_product ON sale_items(product_id);');

        // CUSTOMERS
        await db.execute('''
          CREATE TABLE customers(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            balance REAL DEFAULT 0,
            imagePath TEXT,
            createdAt TEXT,
            updatedAt TEXT
          );
        ''');

        // PAYMENTS (legacy)
        await db.execute('''
          CREATE TABLE payments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            status TEXT
          );
        ''');

        // CUSTOMER PAYMENTS
        await db.execute('''
          CREATE TABLE IF NOT EXISTS customer_payments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customerId INTEGER NOT NULL,
            amount REAL NOT NULL,
            note TEXT,
            createdAt TEXT,
            FOREIGN KEY(customerId) REFERENCES customers(id)
          );
        ''');

        // PRODUCTS
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            stock INTEGER NOT NULL,
            price REAL NOT NULL,
            category TEXT,
            imagePath TEXT,
            createdAt TEXT,
            updatedAt TEXT
          );
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);');

        // Default user
        await db.insert('user', {'pin': '3030', 'password': 'gulfam'});
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 → v2
        if (oldVersion < 2) {
          try { await db.execute('ALTER TABLE products ADD COLUMN category TEXT;'); } catch (_) {}
          try { await db.execute('ALTER TABLE products ADD COLUMN imagePath TEXT;'); } catch (_) {}
          try { await db.execute('ALTER TABLE products ADD COLUMN createdAt TEXT;'); } catch (_) {}
          try { await db.execute('ALTER TABLE products ADD COLUMN updatedAt TEXT;'); } catch (_) {}
          try { await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);'); } catch (_) {}
        }

        // v2 → v3
        if (oldVersion < 3) {
          try { await db.execute('ALTER TABLE customers ADD COLUMN balance REAL DEFAULT 0;'); } catch (_) {}
          try { await db.execute('ALTER TABLE customers ADD COLUMN imagePath TEXT;'); } catch (_) {}
          try { await db.execute('ALTER TABLE customers ADD COLUMN createdAt TEXT;'); } catch (_) {}
          try { await db.execute('ALTER TABLE customers ADD COLUMN updatedAt TEXT;'); } catch (_) {}
        }

        // v3 → v4
        if (oldVersion < 4) {
          final cols = (await db.rawQuery('PRAGMA table_info(sales);'))
              .map((e) => e['name'] as String)
              .toSet();

          if (!cols.contains('customerId')) {
            try { await db.execute('ALTER TABLE sales ADD COLUMN customerId INTEGER;'); } catch (_) {}
          }
          if (!cols.contains('subtotal')) {
            try {
              await db.execute('ALTER TABLE sales ADD COLUMN subtotal REAL;');
              await db.execute('UPDATE sales SET subtotal = IFNULL(total,0);');
            } catch (_) {}
          }
          if (!cols.contains('tax')) {
            try { await db.execute('ALTER TABLE sales ADD COLUMN tax REAL DEFAULT 0;'); } catch (_) {}
          }
          if (!cols.contains('paymentMethod')) {
            try { await db.execute("ALTER TABLE sales ADD COLUMN paymentMethod TEXT;"); } catch (_) {}
          }
          if (!cols.contains('isPaid')) {
            try { await db.execute('ALTER TABLE sales ADD COLUMN isPaid INTEGER DEFAULT 1;'); } catch (_) {}
          }
          if (!cols.contains('createdAt')) {
            try {
              await db.execute('ALTER TABLE sales ADD COLUMN createdAt TEXT;');
              await db.execute('UPDATE sales SET createdAt = datetime("now");');
            } catch (_) {}
          }

          try {
            await db.execute('UPDATE sales SET total = IFNULL(subtotal,0) + IFNULL(tax,0) WHERE total IS NULL;');
          } catch (_) {}

          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS sale_items(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sale_id INTEGER NOT NULL,
                product_id INTEGER NOT NULL,
                qty INTEGER NOT NULL,
                price_at_sale REAL NOT NULL,
                FOREIGN KEY(sale_id) REFERENCES sales(id),
                FOREIGN KEY(product_id) REFERENCES products(id)
              );
            ''');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id);');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_sale_items_product ON sale_items(product_id);');
          } catch (_) {}
        }
      },
    );
  }

  // ---------------- AUTH ----------------
  static Future<Map<String, dynamic>?> login(String pin, String password) async {
    final db = await database;
    final result = await db.query(
      'user',
      where: 'pin = ? OR password = ?',
      whereArgs: [pin, password],
      limit: 1,
    );
    return result.isNotEmpty ? result.first : null;
  }

  // ---------------- REPORT HELPERS ----------------
  static String _whereForPeriod(ReportPeriod p) {
    switch (p) {
      case ReportPeriod.day:
        return 'date(s.createdAt) = date("now")';
      case ReportPeriod.week:
        return 'date(s.createdAt) >= date("now","-6 days")';
      case ReportPeriod.month:
        return "strftime('%Y-%m', s.createdAt) = strftime('%Y-%m','now')";
    }
  }


  /// ✅ Fixed alias (cnt → count)
  static Future<Map<String, dynamic>> salesSummary(ReportPeriod p) async {
    final db = await database;
    final where = _whereForPeriod(p);
    final row = await db.rawQuery('''
      SELECT 
        IFNULL(SUM(total), 0) AS total,
        COUNT(*) AS count
      FROM sales
      WHERE $where
    ''');
    return {
      'total': (row.first['total'] as num?)?.toDouble() ?? 0.0,
      'count': (row.first['count'] as num?)?.toInt() ?? 0,
    };
  }

  /// Sale history with aggregated item names for a period (optionally filtered by customerId)
  static Future<List<Map<String, dynamic>>> saleHistory(
      ReportPeriod p, {
        int? customerId,
        int limit = 200,
      }) async {
    final db = await database;
    final where = _whereForPeriod(p);
    final args = <dynamic>[];
    var customerWhere = '';
    if (customerId != null) {
      customerWhere = ' AND s.customerId = ?';
      args.add(customerId);
    }

    // ✅ Use table aliases for all columns to avoid ambiguity
    final rows = await db.rawQuery('''
    SELECT
      s.id,
      s.total,
      s.createdAt,
      c.name AS customerName,
      GROUP_CONCAT(p.name || ' x' || si.qty, ', ') AS items
    FROM sales s
    LEFT JOIN customers c ON c.id = s.customerId
    LEFT JOIN sale_items si ON si.sale_id = s.id
    LEFT JOIN products p ON p.id = si.product_id
    WHERE $where $customerWhere
    GROUP BY s.id
    ORDER BY s.createdAt DESC, s.id DESC
    LIMIT ?
  ''', [...args, limit]);

    return rows.map((r) => {
      'id': r['id'],
      'total': (r['total'] as num?)?.toDouble() ?? 0.0,
      'createdAt': (r['createdAt'] as String?) ?? '',
      'customerName': (r['customerName'] as String?) ?? 'Walk-in',
      'items': (r['items'] as String?) ?? '-',
    }).toList();
  }

  // ---------------- SALES ----------------
  static Future<int> createSale({
    int? customerId,
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    required bool isPaid,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.transaction<int>((txn) async {
      final saleId = await txn.insert('sales', {
        'customerId': customerId,
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'paymentMethod': paymentMethod,
        'isPaid': isPaid ? 1 : 0,
        'createdAt': now,
      });

      for (final it in items) {
        final int productId = it['productId'] as int;
        final int qty = it['qty'] as int;
        final double price = (it['price'] as num).toDouble();

        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': productId,
          'qty': qty,
          'price_at_sale': price,
        });

        await txn.rawUpdate(
          'UPDATE products SET stock = MAX(stock - ?, 0), updatedAt = ? WHERE id = ?',
          [qty, now, productId],
        );
      }

      if (!isPaid && customerId != null) {
        await txn.rawUpdate(
          'UPDATE customers SET balance = IFNULL(balance,0) - ?, updatedAt = ? WHERE id = ?',
          [total, now, customerId],
        );
      }

      return saleId;
    });
  }

  // ---------------- PAYMENT & LEDGER ----------------
  static Future<double> totalOutstanding() async {
    final db = await database;
    final row = await db.rawQuery('SELECT IFNULL(SUM(ABS(balance)), 0) as s FROM customers WHERE balance < 0');
    return (row.first['s'] as num?)?.toDouble() ?? 0.0;
  }

  static Future<List<Map<String, dynamic>>> listCustomersWithBalances({
    String? search,
    String status = 'all',
  }) async {
    final db = await database;
    String where = '1=1';
    final args = <dynamic>[];

    if (search != null && search.trim().isNotEmpty) {
      where += ' AND (LOWER(name) LIKE ? OR LOWER(IFNULL(phone,"")) LIKE ?)';
      args.add('%${search.toLowerCase()}%');
      args.add('%${search.toLowerCase()}%');
    }

    if (status == 'pending') {
      where += ' AND IFNULL(balance,0) < 0';
    } else if (status == 'settled') {
      where += ' AND IFNULL(balance,0) >= 0';
    }

    final rows = await db.query(
      'customers',
      columns: ['id', 'name', 'phone', 'balance', 'imagePath', 'updatedAt', 'createdAt'],
      where: where,
      whereArgs: args,
      orderBy: 'LOWER(name) ASC',
    );
    return rows;
  }

  static Future<void> addCustomerPayment({
    required int customerId,
    required double amount,
  }) async {
    if (amount <= 0) return;
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.insert('payments', {'status': 'paid'});
      await txn.insert('customer_payments', {
        'customerId': customerId,
        'amount': amount,
        'note': '',
        'createdAt': now,
      });
      await txn.rawUpdate(
        'UPDATE customers SET balance = IFNULL(balance,0) + ?, updatedAt = ? WHERE id = ?',
        [amount, now, customerId],
      );
    });
  }

  static Future<List<Map<String, dynamic>>> customerLedgerHistory(int customerId) async {
    final db = await database;
    final salesRows = await db.rawQuery('''
      SELECT createdAt AS dt, total * -1 AS amount, 'Sale (Pay Later)' AS label
      FROM sales
      WHERE customerId = ? AND IFNULL(isPaid,1) = 0
    ''', [customerId]);

    final paymentsRows = await db.rawQuery('''
      SELECT createdAt AS dt, amount, 'Payment' AS label
      FROM customer_payments
      WHERE customerId = ?
    ''', [customerId]);

    final out = <Map<String, dynamic>>[];
    out.addAll(salesRows.map((e) => {
      'date': e['dt'],
      'amount': (e['amount'] as num?)?.toDouble() ?? 0.0,
      'label': e['label'] as String,
    }));
    out.addAll(paymentsRows.map((e) => {
      'date': e['dt'],
      'amount': (e['amount'] as num?)?.toDouble() ?? 0.0,
      'label': e['label'] as String,
    }));

    // ✅ Null-safe sort
    out.sort((a, b) {
      final dateA = a['date'] as String?;
      final dateB = b['date'] as String?;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return out;
  }

  static Future<void> recordCustomerPayment({
    required int customerId,
    required double amount,
    String? note,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert('customer_payments', {
      'customerId': customerId,
      'amount': amount,
      'note': note ?? '',
      'createdAt': now,
    });
    await db.rawUpdate(
      'UPDATE customers SET balance = IFNULL(balance,0) + ?, updatedAt = ? WHERE id = ?',
      [amount, now, customerId],
    );
  }

  static Future<List<Map<String, dynamic>>> customerLedger(int customerId) async {
    final db = await database;

    final sales = await db.rawQuery('''
      SELECT id, total AS amount, 'sale' AS type, createdAt
      FROM sales
      WHERE customerId = ?
    ''', [customerId]);

    final payments = await db.rawQuery('''
      SELECT id, amount, 'payment' AS type, createdAt
      FROM customer_payments
      WHERE customerId = ?
    ''', [customerId]);

    final ledger = [...sales, ...payments];
    ledger.sort((a, b) {
      final dateA = a['createdAt'] ?? '';
      final dateB = b['createdAt'] ?? '';
      return dateB.toString().compareTo(dateA.toString());
    });

    return ledger;
  }

  /// Dashboard Summary
  static Future<Map<String, dynamic>> getDashboardData() async {
    final db = await database;

    final todayRow = await db.rawQuery(
        'SELECT IFNULL(SUM(total), 0) AS s FROM sales WHERE date(createdAt) = date("now")');
    final double todaySales = (todayRow.first['s'] as num?)?.toDouble() ?? 0.0;

    final totalCustomers =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM customers')) ?? 0;

    final pendingPayments = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM customers WHERE IFNULL(balance,0) < 0')) ?? 0;

    final lowStock = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM products WHERE stock < 5')) ?? 0;

    return {
      'todaySales': todaySales,
      'totalCustomers': totalCustomers,
      'pendingPayments': pendingPayments,
      'lowStock': lowStock,
    };
  }
}
