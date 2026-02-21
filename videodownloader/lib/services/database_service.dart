import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/download_item.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('video_downloader.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE downloads (
        id $idType,
        title $textType,
        url $textType,
        platform $textType,
        thumbnail $textType,
        fileSize $textType,
        filePath TEXT,
        downloadDate $intType,
        isCompleted INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insertDownload(DownloadItem item) async {
    final db = await instance.database;
    return await db.insert('downloads', item.toMap());
  }

  Future<List<DownloadItem>> getAllDownloads() async {
    final db = await instance.database;
    final result = await db.query(
      'downloads',
      orderBy: 'downloadDate DESC',
    );
    return result.map((json) => DownloadItem.fromMap(json)).toList();
  }

  Future<List<DownloadItem>> getRecentDownloads({int limit = 5}) async {
    final db = await instance.database;
    final result = await db.query(
      'downloads',
      orderBy: 'downloadDate DESC',
      limit: limit,
    );
    return result.map((json) => DownloadItem.fromMap(json)).toList();
  }

  Future<int> updateDownload(DownloadItem item) async {
    final db = await instance.database;
    return db.update(
      'downloads',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteDownload(int id) async {
    final db = await instance.database;
    return await db.delete(
      'downloads',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
