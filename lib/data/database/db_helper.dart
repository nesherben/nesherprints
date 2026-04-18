import 'package:path/path.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nesher_erp_v6.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. SETTINGS (Igual)
    await db.execute('''
      CREATE TABLE ${DbTables.settings} (
        ${DbColumns.settingKey} TEXT UNIQUE,
        ${DbColumns.settingValue} REAL,
        id INTEGER PRIMARY KEY AUTOINCREMENT
      )
    ''');

    // 2. MATERIALS (Igual)
    await db.execute('''
      CREATE TABLE ${DbTables.materials} (
        ${DbColumns.materialId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbColumns.materialName} TEXT NOT NULL,
        color TEXT NOT NULL,
        ${DbColumns.materialType} TEXT NOT NULL,
        ${DbColumns.materialCostPerKg} REAL NOT NULL,
        stock_g REAL NOT NULL
      )
    ''');

    // 3. NUEVA TABLA: CLIENTS
    await db.execute('''
      CREATE TABLE ${DbTables.clients} (
        ${DbColumns.clientId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbColumns.clientName} TEXT NOT NULL,
        ${DbColumns.clientPhone} TEXT,
        ${DbColumns.clientEmail} TEXT,
        notes TEXT
      )
    ''');

    // Tabla orders (mantenemos client_id de la v5)
    await db.execute('''
    CREATE TABLE ${DbTables.orders} (
      ${DbColumns.orderId} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DbColumns.orderClientId} INTEGER,
      ${DbColumns.orderName} TEXT NOT NULL,
      ${DbColumns.orderPrice} REAL NOT NULL,
      ${DbColumns.orderPaidAmount} REAL DEFAULT 0.0,
      date TEXT NOT NULL,
      ${DbColumns.orderStatus} TEXT NOT NULL,
      ${DbColumns.orderIsPainted} INTEGER NOT NULL,
      notes TEXT,
      FOREIGN KEY (${DbColumns.orderClientId}) REFERENCES ${DbTables.clients} (${DbColumns.clientId})
    )
  ''');
    // 5. ORDER_ITEMS (Igual)
    await db.execute('''
      CREATE TABLE ${DbTables.orderItems} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbColumns.orderForeignId} INTEGER NOT NULL,
        ${DbColumns.materialForeignId} INTEGER NOT NULL,
        grams_used REAL NOT NULL,
        FOREIGN KEY (${DbColumns.orderForeignId}) REFERENCES ${DbTables.orders} (${DbColumns.orderId}),
        FOREIGN KEY (${DbColumns.materialForeignId}) REFERENCES ${DbTables.materials} (${DbColumns.materialId})
      )
    ''');

    // 6. ORDER_WASTE (Igual)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.orderWaste} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbColumns.orderForeignId} INTEGER NOT NULL,
        ${DbColumns.materialForeignId} INTEGER NOT NULL,
        grams_wasted REAL NOT NULL,
        reason TEXT,
        date TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (${DbColumns.orderForeignId}) REFERENCES ${DbTables.orders} (${DbColumns.orderId}) ON DELETE CASCADE,
        FOREIGN KEY (${DbColumns.materialForeignId}) REFERENCES ${DbTables.materials} (${DbColumns.materialId})
      )
    ''');
    // NUEVA TABLA: order_plates
    await db.execute('''
    CREATE TABLE ${DbTables.orderPlates} (
      ${DbColumns.plateId} INTEGER PRIMARY KEY AUTOINCREMENT,
      ${DbColumns.plateOrderId} INTEGER NOT NULL,
      ${DbColumns.plateName} TEXT NOT NULL,
      ${DbColumns.plateGrams} REAL NOT NULL,
      ${DbColumns.plateMinutes} REAL NOT NULL,
      ${DbColumns.plateMaterialId} INTEGER NOT NULL,
      ${DbColumns.plateStatus} TEXT DEFAULT '${OrderStatus.pending}', -- 'Pending', 'Success', 'Failed'
      FOREIGN KEY (${DbColumns.plateOrderId}) REFERENCES ${DbTables.orders} (${DbColumns.orderId}) ON DELETE CASCADE
    )
  ''');

    // Inserts por defecto (Settings)
    await db.insert(DbTables.settings, {
      DbColumns.settingKey: SettingKeys.margenBeneficio,
      DbColumns.settingValue: FinanceDefaults.defaultBenefitMargin,
    });
    await db.insert(DbTables.settings, {
      DbColumns.settingKey: SettingKeys.costeHoraPintado,
      DbColumns.settingValue: FinanceDefaults.defaultPaintingCost,
    });
    await db.insert(DbTables.settings, {
      DbColumns.settingKey: SettingKeys.costePlacaExtra,
      DbColumns.settingValue: 2.50,
    });
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
