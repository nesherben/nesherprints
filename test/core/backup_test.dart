import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/database/db_schema.dart';

void main() {
  late Directory dir;
  late String path;

  setUp(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    dir = Directory.systemTemp.createTempSync('nesher_backup_');
    path = p.join(dir.path, 'datos.db');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  List<String> backups() => [
    for (final f in dir.listSync())
      if (p.basename(f.path).startsWith('datos.db.bak-')) p.basename(f.path),
  ];

  Future<void> createV3Database() async {
    final raw = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE settings (key TEXT UNIQUE, value REAL, '
            'id INTEGER PRIMARY KEY AUTOINCREMENT)',
          );
          await db.execute(
            'CREATE TABLE orders (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'client_id INTEGER, name TEXT NOT NULL, price REAL NOT NULL, '
            'paid_amount REAL DEFAULT 0.0, date TEXT NOT NULL, '
            'status TEXT NOT NULL, is_painted INTEGER NOT NULL, notes TEXT, '
            'attempts REAL NOT NULL DEFAULT 1, '
            'paint_hours REAL NOT NULL DEFAULT 0, '
            'paint_colors REAL NOT NULL DEFAULT 0, cost_override REAL)',
          );
          await db.insert('orders', {
            'name': 'Mi pedido',
            'price': 42,
            'date': '2026-11-01',
            'status': 'Draft',
            'is_painted': 0,
          });
        },
      ),
    );
    await raw.close();
  }

  test('copia el archivo antes de migrar a una versión nueva', () async {
    await createV3Database();
    expect(backups(), isEmpty);

    final db = AppDatabase.file(path);
    final opened = await db.database;
    expect(await opened.getVersion(), DbSchema.version);
    expect(
      (await opened.query('orders')).single['name'],
      'Mi pedido',
      reason: 'los datos se conservan',
    );
    await db.close();

    final names = backups();
    expect(names, hasLength(1));
    expect(names.single, startsWith('datos.db.bak-v3-'));

    // La copia conserva la versión y los datos antiguos.
    final backup = await databaseFactoryFfi.openDatabase(
      p.join(dir.path, names.single),
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    );
    expect(await backup.getVersion(), 3);
    expect((await backup.query('orders')).single['name'], 'Mi pedido');
    await backup.close();
  });

  test('no copia si la base de datos ya está al día', () async {
    await createV3Database();
    final first = AppDatabase.file(path);
    await first.database;
    await first.close();
    expect(backups(), hasLength(1));

    final again = AppDatabase.file(path);
    await again.database;
    await again.close();

    expect(backups(), hasLength(1), reason: 'no hay otra migración');
  });

  test('una base de datos nueva no genera copia', () async {
    final db = AppDatabase.file(path);
    await db.database;
    await db.close();
    expect(backups(), isEmpty);
  });
}
