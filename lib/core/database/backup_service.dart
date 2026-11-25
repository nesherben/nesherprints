import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/errors/app_exception.dart';

/// Copias de seguridad de la base de datos y exportaciones a archivo, en
/// carpetas junto a la base de datos (`backups/` y `exports/`).
class BackupService {
  BackupService(this._db, {String? baseDir}) : _baseDir = baseDir;

  final AppDatabase _db;

  /// Carpeta base (por defecto, la de la base de datos). Solo los tests la
  /// cambian.
  final String? _baseDir;

  /// Cuántas copias automáticas se conservan.
  static const int keepBackups = 15;

  Future<Directory> _folder(String name) async {
    final dir = Directory(join(_baseDir ?? await getDatabasesPath(), name));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _stamp(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  /// Crea una copia consistente de la base de datos y devuelve su ruta.
  Future<String> backupNow({DateTime? now}) async {
    final dir = await _folder('backups');
    final path = join(dir.path, 'nesher-${_stamp(now ?? DateTime.now())}.db');
    try {
      final db = await _db.database;
      await db.execute('VACUUM INTO ?', [path]);
    } on Object catch (e) {
      throw AppException('No se pudo crear la copia de seguridad: $e');
    }
    await _prune(dir);
    return path;
  }

  /// Crea una copia solo si hoy aún no se hizo ninguna. Devuelve la ruta si
  /// la creó. Nunca lanza: una copia fallida no debe impedir abrir la app.
  Future<String?> backupIfDue({DateTime? now}) async {
    try {
      final today = _stamp(now ?? DateTime.now()).substring(0, 8);
      final dir = await _folder('backups');
      final done = dir.listSync().any(
        (f) => basename(f.path).startsWith('nesher-$today'),
      );
      if (done) return null;
      return await backupNow(now: now);
    } on Object {
      return null;
    }
  }

  /// Borra las copias más antiguas por encima de [keepBackups].
  Future<void> _prune(Directory dir) async {
    final files = [
      for (final f in dir.listSync())
        if (f is File && basename(f.path).startsWith('nesher-')) f,
    ]..sort((a, b) => basename(b.path).compareTo(basename(a.path)));
    for (final old in files.skip(keepBackups)) {
      try {
        await old.delete();
      } on Object {
        // Un archivo en uso se borrará en la próxima copia.
      }
    }
  }

  /// Guarda [text] en `exports/<nombre>` y devuelve la ruta.
  Future<String> export(String fileName, String text) async {
    final dir = await _folder('exports');
    final file = File(join(dir.path, fileName));
    await file.writeAsString(text);
    return file.path;
  }

  /// Carpeta de las copias (para abrirla desde la app).
  Future<String> backupsFolder() async => (await _folder('backups')).path;
}
