import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nesherprints/core/database/db_schema.dart';

/// Punto de acceso a la base de datos SQLite.
///
/// - [AppDatabase.instance]: el archivo real de la app ([kDbFileName]).
/// - [AppDatabase.file]: un archivo concreto (tests de migración).
/// - [AppDatabase.inMemory]: en memoria, sin tocar datos reales (tests).
///
/// Antes de subir de versión el esquema, se hace una copia del archivo junto
/// al original (`<archivo>.bak-v<versión>-<fecha>`).
class AppDatabase {
  AppDatabase._(this._open);

  static final AppDatabase instance = AppDatabase._(() => _openFile(null));

  /// Base de datos en un archivo concreto.
  factory AppDatabase.file(String path) => AppDatabase._(() => _openFile(path));

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

  static Future<Database> _openFile(String? customPath) async {
    final path = customPath ?? join(await getDatabasesPath(), kDbFileName);
    await _backupBeforeMigration(path);
    return openDatabase(
      path,
      version: DbSchema.version,
      onCreate: DbSchema.onCreate,
      onUpgrade: DbSchema.onUpgrade,
      onOpen: DbSchema.onOpen,
    );
  }

  /// Copia el archivo si existe y su versión es anterior a la actual.
  static Future<void> _backupBeforeMigration(String path) async {
    final file = File(path);
    if (!await file.exists()) return;

    final probe = await openDatabase(
      path,
      readOnly: true,
      singleInstance: false,
    );
    final version = await probe.getVersion();
    await probe.close();
    if (version == 0 || version >= DbSchema.version) return;

    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}${two(now.second)}';
    await file.copy('$path.bak-v$version-$stamp');
  }
}
