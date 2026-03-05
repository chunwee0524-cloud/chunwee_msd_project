import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/diary_entry.dart';
import 'app_database.dart';

class DiaryDao {
  static const _kCurrentUser = 'current_user';

  Future<String> _userId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrentUser) ?? 'default';
  }

  Future<int> insertEntry(DiaryEntry entry) async {
    final db = await AppDatabase.instance.database;
    final uid = await _userId();

    final map = entry.toMap();
    map['userId'] = uid;

    return db.insert(
      'diary_entries',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DiaryEntry>> getAllEntries() async {
    final db = await AppDatabase.instance.database;
    final uid = await _userId();

    final rows = await db.query(
      'diary_entries',
      where: 'userId = ?',
      whereArgs: [uid],
      orderBy: 'createdAt DESC',
    );

    return rows.map((e) => DiaryEntry.fromMap(e)).toList();
  }

  Future<int> deleteEntry(int id) async {
    final db = await AppDatabase.instance.database;
    final uid = await _userId();

    return db.delete(
      'diary_entries',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, uid],
    );
  }
}