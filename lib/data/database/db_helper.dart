import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Patrón Singleton: Garantiza que solo haya una conexión a la base de datos abierta
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nesher_erp.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Abre la base de datos y llama a _createDB si es la primera vez que se ejecuta
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // --- DEFINICIÓN DE LA ARQUITECTURA DE DATOS ---
  Future _createDB(Database db, int version) async {
    // 1. TABLA DE CONFIGURACIÓN GLOBAL (El Panel Admin)
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value REAL NOT NULL
      )
    ''');

    // 2. TABLA DE INVENTARIO (Resinas y Filamentos con sus costes propios)
    await db.execute('''
      CREATE TABLE materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL, -- 'resin' o 'filament'
        color TEXT,
        cost_per_kg REAL NOT NULL, -- ¡Justo lo que comentabas!
        stock_g REAL NOT NULL
      )
    ''');

    // 3. TABLA DE PEDIDOS (Conexión con el material usado)
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        grams REAL NOT NULL,
        plates INTEGER NOT NULL,
        is_painted INTEGER NOT NULL,
        material_id INTEGER, -- Relación directa con el material gastado
        FOREIGN KEY (material_id) REFERENCES materials (id)
      )
    ''');

    // INSERCIÓN DE VALORES POR DEFECTO PARA EL PANEL ADMIN
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

  // Cerrar la base de datos (buena práctica)
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
