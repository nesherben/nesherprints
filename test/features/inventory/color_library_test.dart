import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/errors/app_exception.dart';
import 'package:nesherprints/features/inventory/data/color_library_repository.dart';
import 'package:nesherprints/features/inventory/domain/color_library.dart';

void main() {
  group('ColorLibrary', () {
    final lib = ColorLibrary.of(const [
      LibraryColor('Azul marino', 0x001F54),
      LibraryColor('Verde azulado', 0x2A9D8F),
      LibraryColor('Negro', 0x2B2B2F),
      LibraryColor('azul MARINO', 0x111111),
    ]);

    test('no repite nombres (sin distinguir mayúsculas)', () {
      expect(lib.entries.map((c) => c.name), [
        'Azul marino',
        'Verde azulado',
        'Negro',
      ]);
      expect(lib.rgbFor('AZUL marino'), 0x001F54);
      expect(lib.rgbFor('desconocido'), isNull);
    });

    test(
      'sugiere por prefijo y luego por contenido, y no repite el exacto',
      () {
        final names = lib.suggest('azul').map((c) => c.name).toList();
        expect(names.first, 'Azul marino', reason: 'empieza por el texto');
        expect(names, contains('Verde azulado'));
        expect(lib.suggest('Azul marino'), isEmpty, reason: 'ya es el exacto');
        expect(lib.suggest('  '), isEmpty);
      },
    );

    test('deduce el color de un texto libre', () {
      expect(lib.guess('PLA negro mate'), 0x2B2B2F);
      expect(lib.guess('xyz'), isNull);
      expect(ColorLibrary.defaults().guess('Rojo fuego'), isNotNull);
    });
  });

  group('ColorLibraryRepository', () {
    late AppDatabase db;
    late ColorLibraryRepository repo;

    setUp(() {
      db = AppDatabase.inMemory();
      repo = ColorLibraryRepository(db);
    });

    tearDown(() => db.close());

    test('una base nueva trae los colores básicos', () async {
      final lib = await repo.load();
      expect(lib.entries.length, ColorLibrary.basics.length);
      expect(lib.rgbFor('Negro'), isNotNull);
    });

    test('se puede borrar un color de serie y añadir uno nuevo', () async {
      var lib = await repo.load();
      await repo.delete(lib.entries.firstWhere((c) => c.name == 'Negro').id!);
      await repo.add('Rojo fuego', 0xD7263D);
      lib = await repo.load();
      expect(lib.rgbFor('Negro'), isNull);
      expect(lib.rgbFor('rojo fuego'), 0xD7263D);
    });

    test('editar cambia nombre y RGB; un nombre repetido falla', () async {
      await repo.add('Cielo', 0x112233);
      final lib = await repo.load();
      final cielo = lib.entries.firstWhere((c) => c.name == 'Cielo');
      await repo.update(cielo.id!, 'Cielo claro', 0x445566);
      expect((await repo.load()).rgbFor('cielo claro'), 0x445566);
      expect(
        () => repo.update(cielo.id!, 'negro', 0x000000),
        throwsA(isA<AppException>()),
      );
      expect(() => repo.add('NEGRO', 1), throwsA(isA<AppException>()));
      expect(() => repo.add('  ', 1), throwsA(isA<AppException>()));
    });

    test('aprender un color no pisa uno ya editado', () async {
      await repo.add('Mi azul', 0x0000FF);
      await repo.addIfMissing('mi azul', 0xFF0000);
      await repo.addIfMissing('Nuevo', 0x00FF00);
      final lib = await repo.load();
      expect(lib.rgbFor('Mi azul'), 0x0000FF);
      expect(lib.rgbFor('Nuevo'), 0x00FF00);
    });

    test('restaurar básicos repone los borrados sin tocar los demás', () async {
      final lib = await repo.load();
      await repo.delete(lib.entries.first.id!);
      await repo.add('Propio', 0x123456);
      await repo.restoreBasics();
      final after = await repo.load();
      expect(after.entries.length, ColorLibrary.basics.length + 1);
      expect(after.rgbFor('Propio'), 0x123456);
    });
  });
}
