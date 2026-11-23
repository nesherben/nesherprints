import 'package:nesherprints/core/constants.dart';
import 'package:nesherprints/data/database/db_helper.dart';

class SettingsRepository {
  final dbHelper = DatabaseHelper.instance;

  // Obtener todos los ajustes en un formato fácil de usar: {'margen_beneficio': 45.0, ...}
  Future<Map<String, double>> getAllSettings() async {
    await dbHelper.ensureTableExists('''
      CREATE TABLE IF NOT EXISTS ${DbTables.settings} (
        ${DbColumns.settingKey} TEXT UNIQUE,
        ${DbColumns.settingValue} REAL,
        id INTEGER PRIMARY KEY AUTOINCREMENT
      )
    ''');
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DbTables.settings);

    Map<String, double> settings = {};
    for (var map in maps) {
      settings[map['key'] as String] = (map['value'] as num).toDouble();
    }
    return settings;
  }

  // Actualizar un valor específico en la base de datos
  Future<int> updateSetting(String key, double value) async {
    await dbHelper.ensureTableExists('''
      CREATE TABLE IF NOT EXISTS ${DbTables.settings} (
        ${DbColumns.settingKey} TEXT UNIQUE,
        ${DbColumns.settingValue} REAL,
        id INTEGER PRIMARY KEY AUTOINCREMENT
      )
    ''');
    final db = await dbHelper.database;
    return await db.update(
      DbTables.settings,
      {DbColumns.settingValue: value},
      where: '${DbColumns.settingKey} = ?',
      whereArgs: [key],
    );
  }
}
