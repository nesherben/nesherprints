import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/core/errors/app_exception.dart';
import 'package:nesherprints/features/inventory/domain/color_library.dart';

/// Biblioteca de colores de filamento que mantiene el usuario.
class ColorLibraryRepository {
  ColorLibraryRepository(this._db);

  final AppDatabase _db;

  Future<ColorLibrary> load() async {
    final db = await _db.database;
    final rows = await db.query(
      ColorLibraryTable.name,
      orderBy: '${ColorLibraryTable.id} ASC',
    );
    return ColorLibrary.of([
      for (final r in rows)
        LibraryColor(
          r[ColorLibraryTable.colorName] as String,
          (r[ColorLibraryTable.rgb] as num).toInt(),
          id: r[ColorLibraryTable.id] as int,
        ),
    ]);
  }

  /// Añade un color; falla si ya hay otro con ese nombre.
  Future<void> add(String name, int rgb) async {
    final clean = _validName(name);
    final db = await _db.database;
    try {
      await db.insert(ColorLibraryTable.name, {
        ColorLibraryTable.colorName: clean,
        ColorLibraryTable.rgb: rgb & 0xFFFFFF,
      });
    } on DatabaseException {
      throw AppException('Ya hay un color llamado "$clean".');
    }
  }

  /// Cambia nombre y RGB de un color; falla si el nombre ya es de otro.
  Future<void> update(int id, String name, int rgb) async {
    final clean = _validName(name);
    final db = await _db.database;
    try {
      await db.update(
        ColorLibraryTable.name,
        {
          ColorLibraryTable.colorName: clean,
          ColorLibraryTable.rgb: rgb & 0xFFFFFF,
        },
        where: '${ColorLibraryTable.id} = ?',
        whereArgs: [id],
      );
    } on DatabaseException {
      throw AppException('Ya hay un color llamado "$clean".');
    }
  }

  /// Añade el color solo si no existe ya (así aprende de los filamentos sin
  /// pisar lo que el usuario haya editado).
  Future<void> addIfMissing(String name, int rgb) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final db = await _db.database;
    await db.insert(ColorLibraryTable.name, {
      ColorLibraryTable.colorName: clean,
      ColorLibraryTable.rgb: rgb & 0xFFFFFF,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete(
      ColorLibraryTable.name,
      where: '${ColorLibraryTable.id} = ?',
      whereArgs: [id],
    );
  }

  /// Vuelve a poner los colores básicos que falten, sin tocar los demás.
  Future<void> restoreBasics() async {
    for (final c in ColorLibrary.basics) {
      await addIfMissing(c.name, c.rgb);
    }
  }

  String _validName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) throw const AppException('Indica el nombre del color.');
    return clean;
  }
}
