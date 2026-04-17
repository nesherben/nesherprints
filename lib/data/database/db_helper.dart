import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Pasamos a la v3 para crear las tablas desde cero
    _database = await _initDB('nesher_erp_v4.db');
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
    // 1. SETTINGS
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value REAL NOT NULL
      )
    ''');

    // 2. MATERIALS
    await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        color TEXT,
        cost_per_kg REAL NOT NULL,
        stock_g REAL NOT NULL
      )
    ''');

    // 3. ORDERS (Ya no tiene material_id)
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        paid_amount REAL DEFAULT 0.0, -- NUEVO: Para adelantos
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        grams REAL NOT NULL,
        plates INTEGER NOT NULL,
        is_painted INTEGER NOT NULL
      )
    ''');

    // 4. ORDER_ITEMS (La tabla puente mágica)
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        material_id INTEGER NOT NULL,
        grams_used REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders (id),
        FOREIGN KEY (material_id) REFERENCES materials (id)
      )
    ''');
    // 5. ORDER_WASTE (NUEVA: Para registrar fallos por pedido)
    await db.execute('''
      CREATE TABLE order_waste (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        material_id INTEGER NOT NULL,
        grams_wasted REAL NOT NULL,
        reason TEXT,
        FOREIGN KEY (order_id) REFERENCES orders (id),
        FOREIGN KEY (material_id) REFERENCES materials (id)
      )
    ''');
    // Valores por defecto
    await db.rawInsert(
      "INSERT INTO settings (key, value) VALUES ('margen_beneficio', 45.0)",
    );
    await db.rawInsert(
      "INSERT INTO settings (key, value) VALUES ('coste_hora_pintado', 15.0)",
    );
    await db.rawInsert(
      "INSERT INTO settings (key, value) VALUES ('coste_placa_extra', 2.50)",
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
