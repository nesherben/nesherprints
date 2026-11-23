import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<PricingSettings> getPricingSettings() async {
    final db = await _db.database;
    final rows = await db.query(SettingsTable.name);
    return PricingSettings.fromMap({
      for (final row in rows)
        row[SettingsTable.key] as String: asDouble(row[SettingsTable.value]),
    });
  }

  /// Guarda los valores con UPDATE: solo actualiza claves que ya existen
  /// (se crean al crear/migrar la base de datos).
  Future<void> savePricingSettings(PricingSettings settings) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final entry in settings.toMap().entries) {
        await txn.update(
          SettingsTable.name,
          {SettingsTable.value: entry.value},
          where: '${SettingsTable.key} = ?',
          whereArgs: [entry.key],
        );
      }
    });
  }
}
