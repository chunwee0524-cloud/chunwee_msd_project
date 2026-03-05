import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bmi_log.dart';
import 'app_database.dart';

class BmiDao {
  static const _kCurrentUser = 'current_user';

  Future<String> _userId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrentUser) ?? 'default';
  }

  Future<int> insertLog(BmiLog log) async {
    final db = await AppDatabase.instance.database;
    final uid = await _userId();

    final map = log.toMap();
    map['userId'] = uid;

    return db.insert(
      'bmi_logs',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BmiLog>> getAllLogs() async {
    final db = await AppDatabase.instance.database;
    final uid = await _userId();

    final rows = await db.query(
      'bmi_logs',
      where: 'userId = ?',
      whereArgs: [uid],
      orderBy: 'createdAt DESC',
    );

    return rows.map((e) => BmiLog.fromMap(e)).toList();
  }

  Future<int> deleteLog(int id) async {
    final db = await AppDatabase.instance.database;
    final uid = await _userId();

    return db.delete(
      'bmi_logs',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, uid],
    );
  }

  Future<void> clearAll() async {
    final db = await AppDatabase.instance.database;
    final uid = await _userId();

    await db.delete(
      'bmi_logs',
      where: 'userId = ?',
      whereArgs: [uid],
    );
  }
}