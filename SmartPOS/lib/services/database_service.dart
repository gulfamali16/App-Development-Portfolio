import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/constants.dart';

/// Database service for SQLite (offline mode)
class DatabaseService {
  static Database? _database;

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        name TEXT NOT NULL,
        photoUrl TEXT,
        createdAt TEXT,
        lastLoginAt TEXT
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        imageUrl TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        syncStatus INTEGER DEFAULT 0
      )
    ''');

    // Products table (updated with new fields)
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        sku TEXT,
        barcode TEXT,
        price REAL NOT NULL,
        costPrice REAL,
        quantity INTEGER NOT NULL DEFAULT 0,
        minStock INTEGER DEFAULT 10,
        unitType TEXT DEFAULT 'item',
        categoryId TEXT,
        imageUrl TEXT,
        createdAt TEXT,
        updatedAt TEXT,
        syncStatus INTEGER DEFAULT 0,
        FOREIGN KEY (categoryId) REFERENCES categories(id)
      )
    ''');

    // Stock movements table
    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT,
        supplier TEXT,
        reference TEXT,
        notes TEXT,
        previousStock INTEGER,
        newStock INTEGER,
        createdAt TEXT,
        syncStatus INTEGER DEFAULT 0,
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');

    // Orders table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        status TEXT NOT NULL,
        items TEXT NOT NULL,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');

    // Sync queue table (for offline operations)
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        table_name TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  /// Upgrade database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add categories table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          imageUrl TEXT,
          createdAt TEXT,
          updatedAt TEXT,
          syncStatus INTEGER DEFAULT 0
        )
      ''');

      // Add new columns to products table
      await db.execute('ALTER TABLE products ADD COLUMN sku TEXT');
      await db.execute('ALTER TABLE products ADD COLUMN costPrice REAL');
      await db.execute('ALTER TABLE products ADD COLUMN minStock INTEGER DEFAULT 10');
      await db.execute('ALTER TABLE products ADD COLUMN unitType TEXT DEFAULT "item"');
      await db.execute('ALTER TABLE products ADD COLUMN categoryId TEXT');
      await db.execute('ALTER TABLE products ADD COLUMN syncStatus INTEGER DEFAULT 0');

      // Add stock movements table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS stock_movements (
          id TEXT PRIMARY KEY,
          productId TEXT NOT NULL,
          type TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          reason TEXT,
          supplier TEXT,
          reference TEXT,
          notes TEXT,
          previousStock INTEGER,
          newStock INTEGER,
          createdAt TEXT,
          syncStatus INTEGER DEFAULT 0,
          FOREIGN KEY (productId) REFERENCES products(id)
        )
      ''');
    }
  }

  /// Close database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Clear all data (for logout or reset)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('products');
    await db.delete('categories');
    await db.delete('stock_movements');
    await db.delete('orders');
    await db.delete('sync_queue');
  }

  /// Insert or update user
  Future<void> saveUser(Map<String, dynamic> userData) async {
    final db = await database;
    await db.insert(
      'users',
      userData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get user by uid
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'uid = ?',
      whereArgs: [uid],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Add operation to sync queue
  Future<void> addToSyncQueue(
    String operation,
    String tableName,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    await db.insert('sync_queue', {
      'operation': operation,
      'table_name': tableName,
      'data': data.toString(),
      'createdAt': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  /// Get pending sync operations
  Future<List<Map<String, dynamic>>> getPendingSyncOperations() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
  }

  /// Mark sync operation as completed
  Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
