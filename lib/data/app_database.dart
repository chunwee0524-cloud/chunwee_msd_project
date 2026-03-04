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
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE diary_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  imagePath TEXT,
  createdAt TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE bmi_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  height REAL NOT NULL,
  weight REAL NOT NULL,
  bmi REAL NOT NULL,
  createdAt TEXT NOT NULL
)
''');

    await db.execute('''
CREATE TABLE calories_daily (
  day TEXT PRIMARY KEY,
  totalCalories INTEGER NOT NULL
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {

    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE bmi_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT,
  height REAL NOT NULL,
  weight REAL NOT NULL,
  bmi REAL NOT NULL,
  createdAt TEXT NOT NULL
)
''');
    }

    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE bmi_history ADD COLUMN name TEXT');
      } catch (_) {}
    }

    if (oldVersion < 4) {
      await db.execute('''
CREATE TABLE calories_daily (
  day TEXT PRIMARY KEY,
  totalCalories INTEGER NOT NULL
)
''');
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}