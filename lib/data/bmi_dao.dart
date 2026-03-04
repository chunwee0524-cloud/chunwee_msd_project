import 'package:sqflite/sqflite.dart';
import '../models/bmi_log.dart';
import 'app_database.dart';

class BmiDao {
  Future<int> insertLog(BmiLog log) async {
    final db = await AppDatabase.instance.database;
    return db.insert(
      'bmi_logs',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BmiLog>> getAllLogs() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'bmi_logs',
      orderBy: 'createdAt DESC',
    );
    return rows.map((e) => BmiLog.fromMap(e)).toList();
  }

  Future<int> deleteLog(int id) async {
    final db = await AppDatabase.instance.database;
    return db.delete('bmi_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await AppDatabase.instance.database;
    await db.delete('bmi_logs');
  }
}