import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  DBHelper._internal();
  factory DBHelper() => _instance;

  Future<Database?> get database async {
    // Si estamos en la web, sqflite devolverá null.
    // Por ahora esto nos permite seguir desarrollando sin que explote.
    try {
      if (_database != null) return _database!;
      _database = await _initDB();
      return _database;
    } catch (e) {
      return null;
    }
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'nesher_prints.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE orders(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            price REAL,
            date TEXT,
            status TEXT,
            grams REAL,
            plates INTEGER,
            is_painted INTEGER
          )
        ''');
      },
    );
  }

  // --- MÉTODOS PARA PEDIDOS ---

  // Guardar un pedido
  Future<int> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    if (db == null) return 0; // Evita error en web
    return await db.insert('orders', order);
  }

  // Leer todos los pedidos
  Future<List<Map<String, dynamic>>> getOrders() async {
    final db = await database;
    if (db == null) return []; // Retorna lista vacía en web por ahora
    return await db.query('orders', orderBy: 'id DESC');
  }
}
