import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/database/backup_service.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/domain/orders_csv.dart';

void main() {
  group('OrdersCsv', () {
    test('cabecera, decimales con coma y textos entrecomillados', () {
      final csv = OrdersCsv.build([
        const OrderSummary(
          order: Order(
            id: 7,
            name: 'Figura; "grande"',
            price: 12.5,
            paidAmount: 10,
            date: '2026-03-01',
            status: OrderStatus.completed,
            costOverride: 4,
          ),
          clientName: 'Ana',
        ),
        const OrderSummary(
          order: Order(
            id: 8,
            name: 'Mío',
            price: 0,
            date: '2026-03-02',
            status: OrderStatus.draft,
            isPersonal: true,
          ),
        ),
      ]);
      final lines = csv.replaceFirst('﻿', '').trim().split('\n');
      expect(lines.first, OrdersCsv.header.join(';'));
      expect(
        lines[1],
        '7;2026-03-01;"Figura; ""grande""";Ana;Completado;12,50;10,00;2,50;'
        '4,00;8,50;',
      );
      expect(lines[2], endsWith(';Si'));
      expect(csv.startsWith('﻿'), isTrue, reason: 'BOM para Excel');
    });
  });

  group('BackupService', () {
    late Directory tmp;
    late AppDatabase db;
    late BackupService service;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('nesher-bk-');
      db = AppDatabase.inMemory();
      service = BackupService(db, baseDir: tmp.path);
    });

    tearDown(() async {
      await db.close();
      tmp.deleteSync(recursive: true);
    });

    test('backupNow crea un archivo de base de datos', () async {
      final path = await service.backupNow(now: DateTime(2026, 5, 3, 10, 30));
      expect(p.basename(path), 'nesher-20260503-103000.db');
      expect(File(path).existsSync(), isTrue);
      expect(File(path).lengthSync(), greaterThan(0));
    });

    test('backupIfDue hace una sola copia al día', () async {
      final day = DateTime(2026, 5, 3, 9);
      expect(await service.backupIfDue(now: day), isNotNull);
      expect(await service.backupIfDue(now: day), isNull);
      expect(
        await service.backupIfDue(now: DateTime(2026, 5, 4, 9)),
        isNotNull,
      );
    });

    test('conserva solo las últimas copias', () async {
      for (var i = 1; i <= BackupService.keepBackups + 3; i++) {
        await service.backupNow(now: DateTime(2026, 1, i));
      }
      final files = Directory(p.join(tmp.path, 'backups')).listSync();
      expect(files, hasLength(BackupService.keepBackups));
      final names = files.map((f) => p.basename(f.path)).toList()..sort();
      expect(names.first, 'nesher-20260104-000000.db');
    });

    test('export guarda el texto en exports/', () async {
      final path = await service.export('x.csv', 'hola');
      expect(File(path).readAsStringSync(), 'hola');
      expect(p.basename(p.dirname(path)), 'exports');
    });
  });
}
