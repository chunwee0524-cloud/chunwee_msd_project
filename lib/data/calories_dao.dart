import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database.dart';
import '../models/calories_day.dart';

class CaloriesDao {
  static const _kCurrentUser = 'current_user';

  Future<String> _userId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrentUser) ?? 'default';
  }

  Future<void> upsertDay(String day, int totalCalories) async {
    final Database db = await AppDatabase.instance.database;
    final uid = await _userId();

    await db.insert(
      'calories_daily',
      {'userId': uid, 'day': day, 'totalCalories': totalCalories},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CaloriesDay>> getAllDays() async {
    final Database db = await AppDatabase.instance.database;
    final uid = await _userId();

    final rows = await db.query(
      'calories_daily',
      where: 'userId = ?',
      whereArgs: [uid],
      orderBy: 'day DESC',
    );

    return rows.map((e) => CaloriesDay.fromMap(e)).toList();
  }

  Future<void> deleteDay(String day) async {
    final Database db = await AppDatabase.instance.database;
    final uid = await _userId();

    await db.delete(
      'calories_daily',
      where: 'userId = ? AND day = ?',
      whereArgs: [uid, day],
    );
  }

  Future<void> clearAll() async {
    final Database db = await AppDatabase.instance.database;
    final uid = await _userId();

    await db.delete(
      'calories_daily',
      where: 'userId = ?',
      whereArgs: [uid],
    );
  }
}