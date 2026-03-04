import 'package:sqflite/sqflite.dart';
import '../models/diary_entry.dart';
import 'app_database.dart';

class DiaryDao {
  Future<int> insertEntry(DiaryEntry entry) async {
    final db = await AppDatabase.instance.database;
    return db.insert(
      'diary_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DiaryEntry>> getAllEntries() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'diary_entries',
      orderBy: 'createdAt DESC',
    );
    return rows.map((e) => DiaryEntry.fromMap(e)).toList();
  }

  Future<int> deleteEntry(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete('diary_entries', where: 'id = ?', whereArgs: [id]);
  }
}