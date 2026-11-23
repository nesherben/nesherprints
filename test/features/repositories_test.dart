import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nesherprints/core/constants/app_constants.dart';
import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/features/clients/data/client_repository.dart';
import 'package:nesherprints/features/clients/domain/client.dart';
import 'package:nesherprints/features/extras/data/extras_repository.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';
import 'package:nesherprints/features/inventory/data/material_repository.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/orders/data/order_repository.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/settings/data/settings_repository.dart';
import 'package:nesherprints/features/settings/domain/pricing_settings.dart';

void main() {
  late AppDatabase db;
  late OrderRepository orders;
  late MaterialRepository materials;
  late ExtrasRepository extras;
  late ClientRepository clients;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase.inMemory();
    orders = OrderRepository(db);
    materials = MaterialRepository(db);
    extras = ExtrasRepository(db);
    clients = ClientRepository(db);
    settings = SettingsRepository(db);
  });

  tearDown(() => db.close());

  Future<int> pla({double stock = 1000}) => materials.save(
    PrintMaterial(
      kind: MaterialKind.filament,
      name: 'PLA',
      color: 'Negro',
      costPerKg: 20,
      stockGrams: stock,
    ),
  );

  Future<int> keychain({int stock = 10}) =>
      extras.save(Extra(name: 'Anilla', unitPrice: 0.5, stock: stock));

  Order newOrder({int? id, int? clientId}) => Order(
    id: id,
    clientId: clientId,
    name: 'Figura',
    price: 30,
    paidAmount: 10,
    date: '2026-11-23',
    status: OrderStatus.draft,
  );

  Future<double> materialStock(int id) async =>
      (await materials.getAll()).firstWhere((m) => m.id == id).stockGrams;

  Future<int> extraStock(int id) async =>
      (await extras.getAll()).firstWhere((e) => e.id == id).stock;

  group('Settings', () {
    test('una BD nueva trae los valores por defecto', () async {
      final s = await settings.getPricingSettings();
      expect(s.profitMarginPercent, 15);
      expect(s.safetyMarginPercent, 15);
      expect(s.paintingCostPerHour, 8);
      expect(s.kwhCost, 0.0375);
      expect(s.filamentPlateFee, 0.5);
      expect(s.resinPlateFee, 1.5);
      expect(s.profitGoal, 5000);
    });

    test('guardar y leer', () async {
      await settings.savePricingSettings(
        const PricingSettings(
          profitMarginPercent: 60,
          paintingCostPerHour: 10,
          kwhCost: 0.05,
        ),
      );
      final s = await settings.getPricingSettings();
      expect(s.profitMarginPercent, 60);
      expect(s.kwhCost, 0.05);
    });

    test('guardar crea una clave que faltaba', () async {
      final raw = await db.database;
      await raw.delete(
        SettingsTable.name,
        where: '${SettingsTable.key} = ?',
        whereArgs: [SettingKeys.kwhCost],
      );
      await settings.savePricingSettings(const PricingSettings(kwhCost: 0.07));
      expect((await settings.getPricingSettings()).kwhCost, 0.07);
    });
  });

  group('Pedidos', () {
    test('crear guarda placas y descuenta piezas extra', () async {
      final matId = await pla();
      final exId = await keychain(stock: 10);
      final clientId = await clients.save(const Client(name: 'Ana'));

      final id = await orders.create(
        newOrder(clientId: clientId),
        plates: [
          OrderPlate(name: 'Base', grams: 100, minutes: 60, materialId: matId),
          OrderPlate(name: 'Tapa', grams: 50, minutes: 30, materialId: matId),
        ],
        extras: [OrderExtraLine(extraId: exId, quantity: 3)],
      );

      expect(await extraStock(exId), 7);
      // Crear NO toca el stock de material.
      expect(await materialStock(matId), 1000);

      final summary = (await orders.getAllWithDetails()).single;
      expect(summary.id, id);
      expect(summary.clientName, 'Ana');
      expect(summary.platesCount, 2);
      expect(summary.theoreticalGrams, 150);
      expect(summary.materialCost, closeTo(3, 1e-9));
      expect(summary.plateNames, 'Base, Tapa');
    });

    test('actualizar sin listas no toca placas ni piezas', () async {
      final matId = await pla();
      final exId = await keychain();
      final id = await orders.create(
        newOrder(),
        plates: [
          OrderPlate(name: 'A', grams: 10, minutes: 1, materialId: matId),
        ],
        extras: [OrderExtraLine(extraId: exId, quantity: 2)],
      );

      await orders.update(newOrder(id: id).copyWith(paidAmount: 30));

      expect((await orders.getPlates(id)).length, 1);
      expect(await extraStock(exId), 8);
      expect((await orders.getAllWithDetails()).single.order.paidAmount, 30);
    });

    test(
      'actualizar piezas devuelve las anteriores y aplica las nuevas',
      () async {
        await pla();
        final exId = await keychain(stock: 10);
        final id = await orders.create(
          newOrder(),
          plates: const [],
          extras: [OrderExtraLine(extraId: exId, quantity: 4)],
        );
        expect(await extraStock(exId), 6);

        await orders.update(
          newOrder(id: id),
          extras: [OrderExtraLine(extraId: exId, quantity: 1)],
        );
        expect(await extraStock(exId), 9);
      },
    );

    test('completar marca pagado y resta el material de las placas', () async {
      final matId = await pla(stock: 1000);
      final id = await orders.create(
        newOrder(),
        plates: [
          OrderPlate(name: 'A', grams: 100, minutes: 1, materialId: matId),
          OrderPlate(name: 'B', grams: 50, minutes: 1, materialId: matId),
        ],
      );

      await orders.complete(id);

      final o = (await orders.getAllWithDetails()).single.order;
      expect(o.status, OrderStatus.completed);
      expect(o.paidAmount, o.price);
      expect(await materialStock(matId), 850);
    });

    test('intentos, horas y colores de pintura se guardan y se leen', () async {
      final id = await orders.create(
        const Order(
          name: 'Pintado',
          price: 50,
          date: '2026-11-23',
          status: OrderStatus.draft,
          isPainted: true,
          attempts: 1.3,
          paintHours: 2.5,
          paintColors: 9,
          costOverride: 12.34,
        ),
        plates: const [],
      );
      final o = (await orders.getAllWithDetails()).single.order;
      expect(o.id, id);
      expect(o.attempts, 1.3);
      expect(o.paintHours, 2.5);
      expect(o.paintColors, 9);
      expect(o.costOverride, 12.34);
    });

    test('un pedido sin esos datos usa intentos 1 y sin coste fijo', () async {
      await orders.create(newOrder(), plates: const []);
      final o = (await orders.getAllWithDetails()).single.order;
      expect(o.attempts, 1);
      expect(o.paintHours, 0);
      expect(o.costOverride, isNull);
    });

    test('cambiar estado solo cambia el estado', () async {
      final id = await orders.create(newOrder(), plates: const []);
      await orders.updateStatus(id, OrderStatus.reserved);
      final o = (await orders.getAllWithDetails()).single.order;
      expect(o.status, OrderStatus.reserved);
      expect(o.paidAmount, 10);
    });

    test('borrar devuelve las piezas al stock', () async {
      final exId = await keychain(stock: 10);
      final id = await orders.create(
        newOrder(),
        plates: const [],
        extras: [OrderExtraLine(extraId: exId, quantity: 4)],
      );
      await orders.delete(id);
      expect(await orders.getAllWithDetails(), isEmpty);
      expect(await extraStock(exId), 10);
    });

    test('merma: registra y resta material', () async {
      final matId = await pla(stock: 1000);
      final id = await orders.create(
        newOrder(),
        plates: [
          OrderPlate(name: 'A', grams: 200, minutes: 1, materialId: matId),
        ],
      );
      await orders.addWaste(
        orderId: id,
        materialId: matId,
        grams: 50,
        reason: 'Se despegó',
      );

      expect(await materialStock(matId), 950);
      final waste = await orders.getAllWaste();
      expect(waste.single.grams, 50);
      expect(waste.single.reason, 'Se despegó');
      final summary = (await orders.getAllWithDetails()).single;
      expect(summary.wastedGrams, 50);
      expect(summary.wasteRatePercent, 25);
    });
  });

  group('Piezas', () {
    test('sumar stock recalcula el precio medio', () async {
      final id = await keychain(stock: 10); // 10 × 0,5 € = 5 €
      final extra = (await extras.getAll()).single;
      await extras.addStock(extra, units: 10, totalPrice: 15);
      final updated = (await extras.getAll()).single;
      expect(updated.id, id);
      expect(updated.stock, 20);
      expect(updated.unitPrice, 1); // (5 + 15) / 20
    });
  });

  group('Migración', () {
    Future<Database> openOld(
      int version,
      Future<void> Function(Database) seed,
    ) async {
      sqfliteFfiInit();
      return databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: version,
          singleInstance: false,
          onCreate: (db, _) => seed(db),
        ),
      );
    }

    Future<Map<String, double>> settingsOf(Database raw) async => {
      for (final r in await raw.query('settings'))
        r['key'] as String: (r['value'] as num).toDouble(),
    };

    Future<Set<Object?>> tablesOf(Database raw) async => (await raw.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    )).map((r) => r['name']).toSet();

    test('v1 → v3 crea las tablas y conserva los datos', () async {
      final raw = await openOld(1, (db) async {
        await db.execute(
          'CREATE TABLE settings (key TEXT UNIQUE, value REAL, '
          'id INTEGER PRIMARY KEY AUTOINCREMENT)',
        );
        await db.insert('settings', {'key': 'margen_beneficio', 'value': 50});
      });
      await DbSchema.onUpgrade(raw, 1, DbSchema.version);
      await DbSchema.onOpen(raw);

      expect(
        await tablesOf(raw),
        containsAll([
          'clients',
          'orders',
          'order_plates',
          'extras',
          'order_extras',
          'materials',
        ]),
      );
      final values = await settingsOf(raw);
      expect(
        values['margen_beneficio'],
        50,
        reason: 'valor editado, se respeta',
      );
      expect(values['coste_kwh'], 0.0375);
      expect(values['tarifa_placa_resina'], 1.5);
      await raw.close();
    });

    test(
      'v2 → v3 añade columnas y actualiza solo los valores por defecto antiguos',
      () async {
        final raw = await openOld(2, (db) async {
          await db.execute(
            'CREATE TABLE settings (key TEXT UNIQUE, value REAL, '
            'id INTEGER PRIMARY KEY AUTOINCREMENT)',
          );
          await db.insert('settings', {'key': 'margen_beneficio', 'value': 45});
          await db.insert('settings', {
            'key': 'coste_hora_pintado',
            'value': 12,
          });
          await db.insert('settings', {
            'key': 'coste_placa_extra',
            'value': 2.5,
          });
          await db.execute(
            'CREATE TABLE orders (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'client_id INTEGER, name TEXT NOT NULL, price REAL NOT NULL, '
            'paid_amount REAL DEFAULT 0.0, date TEXT NOT NULL, status TEXT NOT NULL, '
            'is_painted INTEGER NOT NULL, notes TEXT)',
          );
          await db.insert('orders', {
            'name': 'Antiguo',
            'price': 10,
            'date': '2026-01-01',
            'status': 'Completed',
            'is_painted': 0,
          });
        });
        await DbSchema.onUpgrade(raw, 2, DbSchema.version);
        await DbSchema.onOpen(raw);

        final values = await settingsOf(raw);
        expect(
          values['margen_beneficio'],
          15,
          reason: '45 era el valor por defecto antiguo',
        );
        expect(
          values['coste_hora_pintado'],
          12,
          reason: 'editado a mano: se respeta',
        );
        expect(
          values['coste_placa_extra'],
          2.5,
          reason: 'obsoleta pero se conserva',
        );
        expect(values['margen_seguridad'], 15);

        final order = (await raw.query('orders')).single;
        expect(order['name'], 'Antiguo');
        expect(order['attempts'], 1);
        expect(order['paint_hours'], 0);
        expect(order['cost_override'], isNull);

        // Reaplicar la migración no falla ni duplica nada.
        await DbSchema.onUpgrade(raw, 2, DbSchema.version);
        // 8 ajustes de la calculadora + la clave obsoleta.
        expect((await settingsOf(raw)).length, 9);
        await raw.close();
      },
    );
  });
}
