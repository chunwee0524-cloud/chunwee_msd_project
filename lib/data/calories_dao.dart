import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../models/calories_day.dart';

class CaloriesDao {
  Future<void> upsertDay(String day, int totalCalories) async {
    final Database db = await AppDatabase.instance.database;

    await db.insert(
      'calories_daily',
      {'day': day, 'totalCalories': totalCalories},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CaloriesDay>> getAllDays() async {
    final Database db = await AppDatabase.instance.database;

    final rows = await db.query(
      'calories_daily',
      orderBy: 'day DESC',
    );

    return rows.map((e) => CaloriesDay.fromMap(e)).toList();
  }

  Future<void> deleteDay(String day) async {
    final Database db = await AppDatabase.instance.database;

    await db.delete(
      'calories_daily',
      where: 'day = ?',
      whereArgs: [day],
    );
  }

  Future<void> clearAll() async {
    final Database db = await AppDatabase.instance.database;
    await db.delete('calories_daily');
  }
}