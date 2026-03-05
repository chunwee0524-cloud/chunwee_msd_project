import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('food_diary.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7, // ✅ bump version
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // ✅ FIXED diary table: comment + createdAt INTEGER
    await db.execute('''
CREATE TABLE diary_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId TEXT NOT NULL,
  imagePath TEXT NOT NULL,
  comment TEXT,
  createdAt INTEGER NOT NULL
)
''');

    await db.execute('''
CREATE TABLE bmi_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId TEXT NOT NULL,
  name TEXT,
  height REAL NOT NULL,
  weight REAL NOT NULL,
  bmi REAL NOT NULL,
  createdAt INTEGER NOT NULL
)
''');

    await db.execute('''
CREATE TABLE calories_daily (
  userId TEXT NOT NULL,
  day TEXT NOT NULL,
  totalCalories INTEGER NOT NULL,
  PRIMARY KEY (userId, day)
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // ---- Existing migrations you already had (keep them)
    if (oldVersion < 5) {
      // diary_entries userId migration (older versions)
      try {
        await db.execute("ALTER TABLE diary_entries ADD COLUMN userId TEXT");
        await db.execute("UPDATE diary_entries SET userId = 'default' WHERE userId IS NULL");
      } catch (_) {
        // ignore
      }
    }

    // ✅ v7: rebuild diary_entries to correct schema (comment + createdAt INTEGER)
    if (oldVersion < 7) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS diary_entries_v7 (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId TEXT NOT NULL,
  imagePath TEXT NOT NULL,
  comment TEXT,
  createdAt INTEGER NOT NULL
)
''');

      // Try migrate from old diary_entries formats:
      // - old columns may be: title, imagePath, createdAt(TEXT), userId
      // - or other earlier shapes
      try {
        await db.execute('''
INSERT INTO diary_entries_v7 (id, userId, imagePath, comment, createdAt)
SELECT
  id,
  COALESCE(userId, 'default') AS userId,
  imagePath,
  -- old apps used "title" for the text; map it into comment
  title AS comment,
  CASE
    WHEN typeof(createdAt) = 'integer' THEN createdAt
    WHEN typeof(createdAt) = 'text' AND createdAt GLOB '[0-9]*' THEN CAST(createdAt AS INTEGER)
    ELSE CAST(strftime('%s', createdAt) AS INTEGER) * 1000
  END AS createdAt
FROM diary_entries
''');
      } catch (_) {
        // If old table doesn't have "title", maybe it already has "comment"
        try {
          await db.execute('''
INSERT INTO diary_entries_v7 (id, userId, imagePath, comment, createdAt)
SELECT
  id,
  COALESCE(userId, 'default') AS userId,
  imagePath,
  comment,
  CASE
    WHEN typeof(createdAt) = 'integer' THEN createdAt
    WHEN typeof(createdAt) = 'text' AND createdAt GLOB '[0-9]*' THEN CAST(createdAt AS INTEGER)
    ELSE CAST(strftime('%s', createdAt) AS INTEGER) * 1000
  END AS createdAt
FROM diary_entries
''');
        } catch (_) {
          // If migration fails, we still keep the new table; old table will be dropped below if it exists.
        }
      }

      // Replace old table with new one
      try {
        await db.execute('DROP TABLE diary_entries');
      } catch (_) {}
      await db.execute('ALTER TABLE diary_entries_v7 RENAME TO diary_entries');
    }
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
  }
}