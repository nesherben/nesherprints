/// Esquema único de la base de datos SQLite.
///
/// IMPORTANTE: los nombres de tablas y columnas son los que ya existen en las
/// bases de datos de los usuarios. No renombrar sin una migración.
library;

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nesherprints/core/constants/app_constants.dart';
import 'package:nesherprints/features/orders/domain/paint_detail.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

/// Nombre del archivo de base de datos (histórico: el "v6" no es la versión
/// del esquema, que se controla con [DbSchema.version]).
const String kDbFileName = 'nesher_erp_v6.db';

class SettingsTable {
  static const name = 'settings';
  static const id = 'id';
  static const key = 'key';
  static const value = 'value';
}

class MaterialsTable {
  static const name = 'materials';
  static const id = 'id';
  static const materialName = 'name';
  static const color = 'color';
  static const type = 'type';
  static const costPerKg = 'cost_per_kg';
  static const stockGrams = 'stock_g';
}

class ClientsTable {
  static const name = 'clients';
  static const id = 'id';
  static const clientName = 'name';
  static const phone = 'phone';
  static const email = 'email';
  static const notes = 'notes';
}

class OrdersTable {
  static const name = 'orders';
  static const id = 'id';
  static const clientId = 'client_id';
  static const orderName = 'name';
  static const price = 'price';
  static const paidAmount = 'paid_amount';
  static const date = 'date';
  static const status = 'status';
  static const isPainted = 'is_painted';
  static const notes = 'notes';

  /// Multiplicador de material y luz por fallos (1 = a la primera). Desde v3.
  static const attempts = 'attempts';
  static const paintHours = 'paint_hours';

  /// Nivel de detalle de la pintura: `few` / `normal` / `many`. Desde v4.
  static const paintDetail = 'paint_detail';

  /// Obsoleta desde v4 (sustituida por [paintDetail]); la columna se conserva.
  static const legacyPaintColors = 'paint_colors';

  /// Coste real fijo (pedidos importados del Excel con otra fórmula). Desde v3.
  static const costOverride = 'cost_override';
}

/// Tabla heredada: ya no se escribe, pero el panel aún la lee.
class OrderItemsTable {
  static const name = 'order_items';
  static const id = 'id';
  static const orderId = 'order_id';
  static const materialId = 'material_id';
  static const gramsUsed = 'grams_used';
}

class OrderWasteTable {
  static const name = 'order_waste';
  static const id = 'id';
  static const orderId = 'order_id';
  static const materialId = 'material_id';
  static const gramsWasted = 'grams_wasted';
  static const reason = 'reason';
  static const date = 'date';
}

class OrderPlatesTable {
  static const name = 'order_plates';
  static const id = 'id';
  static const orderId = 'order_id';
  static const plateName = 'name';
  static const grams = 'grams';
  static const minutes = 'minutes';
  static const materialId = 'material_id';
  static const status = 'status';
}

class ExtrasTable {
  static const name = 'extras';
  static const id = 'id';
  static const extraName = 'name';
  static const price = 'price';
  static const stock = 'stock';
  static const unit = 'unit';
}

class OrderExtrasTable {
  static const name = 'order_extras';
  static const id = 'id';
  static const orderId = 'order_id';
  static const extraId = 'extra_id';
  static const quantity = 'quantity';
  static const unitPrice = 'unit_price';
}

class DbSchema {
  DbSchema._();

  /// Versión del esquema (PRAGMA user_version).
  static const int version = 4;

  static const String _createSettings =
      '''
    CREATE TABLE IF NOT EXISTS ${SettingsTable.name} (
      ${SettingsTable.key} TEXT UNIQUE,
      ${SettingsTable.value} REAL,
      ${SettingsTable.id} INTEGER PRIMARY KEY AUTOINCREMENT
    )''';

  static const String _createMaterials =
      '''
    CREATE TABLE IF NOT EXISTS ${MaterialsTable.name} (
      ${MaterialsTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${MaterialsTable.materialName} TEXT NOT NULL,
      ${MaterialsTable.color} TEXT NOT NULL,
      ${MaterialsTable.type} TEXT NOT NULL,
      ${MaterialsTable.costPerKg} REAL NOT NULL,
      ${MaterialsTable.stockGrams} REAL NOT NULL
    )''';

  static const String _createClients =
      '''
    CREATE TABLE IF NOT EXISTS ${ClientsTable.name} (
      ${ClientsTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${ClientsTable.clientName} TEXT NOT NULL,
      ${ClientsTable.phone} TEXT,
      ${ClientsTable.email} TEXT,
      ${ClientsTable.notes} TEXT
    )''';

  static const String _createOrders =
      '''
    CREATE TABLE IF NOT EXISTS ${OrdersTable.name} (
      ${OrdersTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${OrdersTable.clientId} INTEGER,
      ${OrdersTable.orderName} TEXT NOT NULL,
      ${OrdersTable.price} REAL NOT NULL,
      ${OrdersTable.paidAmount} REAL DEFAULT 0.0,
      ${OrdersTable.date} TEXT NOT NULL,
      ${OrdersTable.status} TEXT NOT NULL,
      ${OrdersTable.isPainted} INTEGER NOT NULL,
      ${OrdersTable.notes} TEXT,
      ${OrdersTable.attempts} REAL NOT NULL DEFAULT 1,
      ${OrdersTable.paintHours} REAL NOT NULL DEFAULT 0,
      ${OrdersTable.legacyPaintColors} REAL NOT NULL DEFAULT 0,
      ${OrdersTable.costOverride} REAL,
      ${OrdersTable.paintDetail} TEXT NOT NULL DEFAULT 'normal',
      FOREIGN KEY (${OrdersTable.clientId}) REFERENCES ${ClientsTable.name} (${ClientsTable.id})
    )''';

  static const String _createOrderItems =
      '''
    CREATE TABLE IF NOT EXISTS ${OrderItemsTable.name} (
      ${OrderItemsTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${OrderItemsTable.orderId} INTEGER NOT NULL,
      ${OrderItemsTable.materialId} INTEGER NOT NULL,
      ${OrderItemsTable.gramsUsed} REAL NOT NULL,
      FOREIGN KEY (${OrderItemsTable.orderId}) REFERENCES ${OrdersTable.name} (${OrdersTable.id}),
      FOREIGN KEY (${OrderItemsTable.materialId}) REFERENCES ${MaterialsTable.name} (${MaterialsTable.id})
    )''';

  static const String _createOrderWaste =
      '''
    CREATE TABLE IF NOT EXISTS ${OrderWasteTable.name} (
      ${OrderWasteTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${OrderWasteTable.orderId} INTEGER NOT NULL,
      ${OrderWasteTable.materialId} INTEGER NOT NULL,
      ${OrderWasteTable.gramsWasted} REAL NOT NULL,
      ${OrderWasteTable.reason} TEXT,
      ${OrderWasteTable.date} TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (${OrderWasteTable.orderId}) REFERENCES ${OrdersTable.name} (${OrdersTable.id}) ON DELETE CASCADE,
      FOREIGN KEY (${OrderWasteTable.materialId}) REFERENCES ${MaterialsTable.name} (${MaterialsTable.id})
    )''';

  static const String _createOrderPlates =
      '''
    CREATE TABLE IF NOT EXISTS ${OrderPlatesTable.name} (
      ${OrderPlatesTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${OrderPlatesTable.orderId} INTEGER NOT NULL,
      ${OrderPlatesTable.plateName} TEXT NOT NULL,
      ${OrderPlatesTable.grams} REAL NOT NULL,
      ${OrderPlatesTable.minutes} REAL NOT NULL,
      ${OrderPlatesTable.materialId} INTEGER NOT NULL,
      ${OrderPlatesTable.status} TEXT DEFAULT 'Pending',
      FOREIGN KEY (${OrderPlatesTable.orderId}) REFERENCES ${OrdersTable.name} (${OrdersTable.id}) ON DELETE CASCADE
    )''';

  static const String _createExtras =
      '''
    CREATE TABLE IF NOT EXISTS ${ExtrasTable.name} (
      ${ExtrasTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${ExtrasTable.extraName} TEXT NOT NULL,
      ${ExtrasTable.price} REAL NOT NULL,
      ${ExtrasTable.stock} INTEGER DEFAULT 0,
      ${ExtrasTable.unit} TEXT DEFAULT ''
    )''';

  static const String _createOrderExtras =
      '''
    CREATE TABLE IF NOT EXISTS ${OrderExtrasTable.name} (
      ${OrderExtrasTable.id} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${OrderExtrasTable.orderId} INTEGER NOT NULL,
      ${OrderExtrasTable.extraId} INTEGER NOT NULL,
      ${OrderExtrasTable.quantity} INTEGER NOT NULL,
      ${OrderExtrasTable.unitPrice} REAL NOT NULL,
      FOREIGN KEY (${OrderExtrasTable.orderId}) REFERENCES ${OrdersTable.name} (${OrdersTable.id}) ON DELETE CASCADE,
      FOREIGN KEY (${OrderExtrasTable.extraId}) REFERENCES ${ExtrasTable.name} (${ExtrasTable.id})
    )''';

  /// Todas las tablas, en orden de dependencias.
  static const List<String> _allTables = [
    _createSettings,
    _createMaterials,
    _createClients,
    _createOrders,
    _createOrderItems,
    _createOrderWaste,
    _createOrderPlates,
    _createExtras,
    _createOrderExtras,
  ];

  /// Base de datos nueva: todas las tablas + ajustes por defecto.
  static Future<void> onCreate(Database db, int version) async {
    for (final sql in _allTables) {
      await db.execute(sql);
    }
    for (final entry in const PricingSettings().toMap().entries) {
      await db.insert(SettingsTable.name, {
        SettingsTable.key: entry.key,
        SettingsTable.value: entry.value,
      });
    }
  }

  /// Migraciones incrementales. Añadir aquí `if (oldVersion < N)`.
  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Garantiza que existen todas las tablas (con el esquema actual) antes de
    // migrar: así las migraciones pueden suponer que están.
    for (final sql in _allTables) {
      await db.execute(sql);
    }

    if (oldVersion < 2) {
      // v2: clientes, placas, piezas y el ajuste "coste placa extra" (obsoleto
      // desde v3, pero se conserva la fila).
      await _insertSettingIfMissing(db, SettingKeys.legacyPlateExtraCost, 2.5);
    }

    if (oldVersion < 3) {
      // v3: fórmulas del Excel. Datos de pintura/intentos por pedido y
      // ajustes nuevos; los ajustes antiguos con su valor por defecto de
      // entonces se actualizan al del Excel (los editados a mano se respetan).
      for (final column in [
        '${OrdersTable.attempts} REAL NOT NULL DEFAULT 1',
        '${OrdersTable.paintHours} REAL NOT NULL DEFAULT 0',
        '${OrdersTable.legacyPaintColors} REAL NOT NULL DEFAULT 0',
        '${OrdersTable.costOverride} REAL',
      ]) {
        await _addColumnIfMissing(db, OrdersTable.name, column);
      }
      for (final entry in const PricingSettings().toMap().entries) {
        await _insertSettingIfMissing(db, entry.key, entry.value);
      }
      await _replaceSettingIf(
        db,
        SettingKeys.profitMargin,
        from: FinanceDefaults.legacyProfitMarginPercent,
        to: FinanceDefaults.profitMarginPercent,
      );
      await _replaceSettingIf(
        db,
        SettingKeys.paintingCostPerHour,
        from: FinanceDefaults.legacyPaintingCostPerHour,
        to: FinanceDefaults.paintingCostPerHour,
      );
    }

    if (oldVersion < 4) {
      // v4: la pintura pasa de "nº de colores" a 3 niveles de detalle.
      // Los colores ya guardados se convierten al nivel que les corresponde;
      // la columna antigua se conserva sin usar.
      final added = await _addColumnIfMissing(
        db,
        OrdersTable.name,
        "${OrdersTable.paintDetail} TEXT NOT NULL DEFAULT 'normal'",
      );
      if (added) {
        const colors = OrdersTable.legacyPaintColors;
        for (final entry in {
          PaintDetail.few: '$colors > 0 AND $colors <= 4',
          PaintDetail.normal: '$colors > 4 AND $colors <= 10',
          PaintDetail.many: '$colors > 10',
        }.entries) {
          await db.rawUpdate(
            'UPDATE ${OrdersTable.name} SET ${OrdersTable.paintDetail} = ? '
            'WHERE ${entry.value}',
            [entry.key.dbValue],
          );
        }
      }
      for (final entry in const PricingSettings().toMap().entries) {
        await _insertSettingIfMissing(db, entry.key, entry.value);
      }
    }
  }

  static Future<bool> _addColumnIfMissing(
    Database db,
    String table,
    String columnDefinition,
  ) async {
    final name = columnDefinition.split(' ').first;
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.any((c) => c['name'] == name)) return false;
    await db.execute('ALTER TABLE $table ADD COLUMN $columnDefinition');
    return true;
  }

  static Future<void> _insertSettingIfMissing(
    Database db,
    String key,
    double value,
  ) async {
    final existing = await db.query(
      SettingsTable.name,
      where: '${SettingsTable.key} = ?',
      whereArgs: [key],
    );
    if (existing.isNotEmpty) return;
    await db.insert(SettingsTable.name, {
      SettingsTable.key: key,
      SettingsTable.value: value,
    });
  }

  static Future<void> _replaceSettingIf(
    Database db,
    String key, {
    required double from,
    required double to,
  }) => db.update(
    SettingsTable.name,
    {SettingsTable.value: to},
    where: '${SettingsTable.key} = ? AND ${SettingsTable.value} = ?',
    whereArgs: [key, from],
  );

  /// Red de seguridad en cada apertura: garantiza que existen todas las
  /// tablas (bases de datos antiguas o incompletas). No modifica datos.
  static Future<void> onOpen(Database db) async {
    for (final sql in _allTables) {
      await db.execute(sql);
    }
  }
}
