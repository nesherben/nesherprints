import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nesherprints/core/database/db_schema.dart';

/// Punto de acceso a la base de datos SQLite.
///
/// En la app se usa [AppDatabase.instance] (archivo [kDbFileName]).
/// En los tests se usa [AppDatabase.inMemory] para no tocar datos reales.
class AppDatabase {
  AppDatabase._(this._open);

  static final AppDatabase instance = AppDatabase._(_openFile);

  /// Base de datos en memoria con el esquema completo (solo tests).
  factory AppDatabase.inMemory() {
    sqfliteFfiInit();
    return AppDatabase._(
      () => databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: DbSchema.version,
          onCreate: DbSchema.onCreate,
          onUpgrade: DbSchema.onUpgrade,
          onOpen: DbSchema.onOpen,
          singleInstance: false,
        ),
      ),
    );
  }

  final Future<Database> Function() _open;
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<void> close() async {
    final db = await _database;
    _database = null;
    await db?.close();
  }

  static Future<Database> _openFile() async {
    final path = join(await getDatabasesPath(), kDbFileName);
    return openDatabase(
      path,
      version: DbSchema.version,
      onCreate: DbSchema.onCreate,
      onUpgrade: DbSchema.onUpgrade,
      onOpen: DbSchema.onOpen,
    );
  }
}
