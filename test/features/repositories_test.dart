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
import 'package:nesherprints/features/orders/domain/order_rules.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';
import 'package:nesherprints/features/orders/domain/paint_detail.dart';
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
      expect(s.profitMarginPercent, 150);
      expect(s.minimumPrice, 5);
      expect(s.kwhPrice, 0.15);
      expect(s.machineCostPerHour, 0.10);
      expect(s.plateCost, 1);
      expect(s.paintPriceSimple, 20);
      expect(s.paintPriceNormal, 60);
      expect(s.paintPriceDetailed, 100);
      expect(s.profitGoal, 5000);
    });

    test('guardar y leer', () async {
      await settings.savePricingSettings(
        const PricingSettings(
          profitMarginPercent: 200,
          kwhPrice: 0.22,
          minimumPrice: 8,
        ),
      );
      final s = await settings.getPricingSettings();
      expect(s.profitMarginPercent, 200);
      expect(s.kwhPrice, 0.22);
      expect(s.minimumPrice, 8);
    });

    test('guardar crea una clave que faltaba', () async {
      final raw = await db.database;
      await raw.delete(
        SettingsTable.name,
        where: '${SettingsTable.key} = ?',
        whereArgs: [SettingKeys.kwhPrice],
      );
      await settings.savePricingSettings(const PricingSettings(kwhPrice: 0.07));
      expect((await settings.getPricingSettings()).kwhPrice, 0.07);
    });
  });

  group('Clientes', () {
    test('K6: borrar un cliente conserva sus pedidos sin cliente', () async {
      final matId = await pla();
      final clientId = await clients.save(const Client(name: 'Ana'));
      await orders.create(
        newOrder(clientId: clientId),
        plates: [
          OrderPlate(name: 'A', grams: 10, minutes: 5, materialId: matId),
        ],
      );

      await clients.delete(clientId);

      expect(await clients.getAll(), isEmpty);
      final order = (await orders.getAllWithDetails()).single;
      expect(order.order.clientId, isNull);
      expect(order.clientName, isNull);
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

    test(
      'setMoney y setClient editan un pedido cerrado con validación',
      () async {
        final matId = await pla();
        final clientId = await clients.save(const Client(name: 'Ana'));
        final id = await orders.create(
          newOrder(),
          plates: [
            OrderPlate(name: 'A', grams: 100, minutes: 60, materialId: matId),
          ],
        );
        await orders.complete(id);

        await orders.setMoney(id, price: 50);
        var o = (await orders.getAllWithDetails()).single.order;
        expect(o.price, 50);
        expect(o.paidAmount, 30, reason: 'completar dejó lo cobrado = precio');

        await orders.setMoney(id, paid: 40);
        o = (await orders.getAllWithDetails()).single.order;
        expect(o.paidAmount, 40);
        expect(o.pendingAmount, 10);

        expect(
          () => orders.setMoney(id, paid: 99),
          throwsA(isA<OrderRuleException>()),
        );
        expect(
          () => orders.setMoney(id, price: -1),
          throwsA(isA<OrderRuleException>()),
        );

        await orders.setClient(id, clientId);
        expect((await orders.getAllWithDetails()).single.clientName, 'Ana');
        await orders.setClient(id, null);
        expect((await orders.getAllWithDetails()).single.clientName, isNull);
      },
    );

    test('setClientMany asigna el cliente a varios pedidos', () async {
      final matId = await pla();
      final clientId = await clients.save(const Client(name: 'Ana'));
      final ids = <int>[];
      for (var i = 0; i < 3; i++) {
        ids.add(
          await orders.create(
            newOrder(),
            plates: [
              OrderPlate(name: 'A', grams: 10, minutes: 5, materialId: matId),
            ],
          ),
        );
      }
      await orders.setClientMany(ids.take(2).toList(), clientId);
      final names = (await orders.getAllWithDetails())
          .map((o) => o.clientName)
          .toList();
      expect(names.where((n) => n == 'Ana'), hasLength(2));
      expect(names.where((n) => n == null), hasLength(1));
    });

    test('marcar como cobrado iguala lo pagado al precio', () async {
      final matId = await pla();
      final id = await orders.create(
        newOrder(),
        plates: [
          OrderPlate(name: 'A', grams: 100, minutes: 60, materialId: matId),
        ],
      );
      expect(
        (await orders.getAllWithDetails()).single.order.pendingAmount,
        greaterThan(0),
      );
      await orders.markPaid(id);
      final o = (await orders.getAllWithDetails()).single.order;
      expect(o.paidAmount, o.price);
      expect(o.pendingAmount, 0);
    });

    test('marcar para mí pone precio y cobro a 0 sin tocar el stock', () async {
      final matId = await pla();
      final id = await orders.create(
        newOrder(),
        plates: [
          OrderPlate(name: 'A', grams: 100, minutes: 60, materialId: matId),
        ],
      );
      await orders.complete(id);
      final stock = await materialStock(matId);

      await orders.markPersonal(id);

      final o = (await orders.getAllWithDetails()).single.order;
      expect(o.isPersonal, isTrue);
      expect(o.price, 0);
      expect(o.paidAmount, 0);
      expect(o.countsAsRevenue, isFalse);
      expect(await materialStock(matId), stock);
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

    test('intentos y detalle de pintura se guardan y se leen', () async {
      final id = await orders.create(
        const Order(
          name: 'Pintado',
          price: 50,
          date: '2026-11-23',
          status: OrderStatus.draft,
          isPainted: true,
          attempts: 1.3,
          paintDetail: PaintDetail.detailed,
          costOverride: 12.34,
        ),
        plates: const [],
      );
      final o = (await orders.getAllWithDetails()).single.order;
      expect(o.id, id);
      expect(o.attempts, 1.3);
      expect(o.paintDetail, PaintDetail.detailed);
      expect(o.costOverride, 12.34);
    });

    test('un pedido sin esos datos usa intentos 1 y sin coste fijo', () async {
      await orders.create(newOrder(), plates: const []);
      final o = (await orders.getAllWithDetails()).single.order;
      expect(o.attempts, 1);
      expect(o.paintDetail, PaintDetail.normal);
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
      await extras.addStock(extra.id!, units: 10, totalPrice: 15);
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

    const settingsTable =
        'CREATE TABLE settings (key TEXT UNIQUE, value REAL, '
        'id INTEGER PRIMARY KEY AUTOINCREMENT)';

    test(
      'v1 → v5 crea las tablas y deja el margen en su valor por defecto',
      () async {
        final raw = await openOld(1, (db) async {
          await db.execute(settingsTable);
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
          150,
          reason:
              'el margen cambió de significado: vuelve al valor por defecto',
        );
        expect(values['precio_kwh'], 0.15);
        expect(values['coste_maquina_hora'], 0.10);
        expect(values['coste_placa'], 1);
        expect(values['precio_minimo'], 5);
        await raw.close();
      },
    );

    test(
      'v2 → v5 añade columnas, respeta ajustes editados y conserva los pedidos',
      () async {
        final raw = await openOld(2, (db) async {
          await db.execute(settingsTable);
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
            'paid_amount REAL DEFAULT 0.0, date TEXT NOT NULL, '
            'status TEXT NOT NULL, is_painted INTEGER NOT NULL, notes TEXT)',
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
        expect(values['margen_beneficio'], 150);
        expect(
          values['coste_hora_pintado'],
          12,
          reason: 'editado a mano: se respeta',
        );
        expect(
          values['coste_placa_extra'],
          2.5,
          reason: 'obsoleta, se conserva',
        );

        final order = (await raw.query('orders')).single;
        expect(order['name'], 'Antiguo');
        expect(order['attempts'], 1);
        expect(order['paint_hours'], 0);
        expect(order['paint_level'], 1, reason: 'pedidos antiguos: normal');
        expect(
          order['cost_override'],
          0,
          reason: 'cerrado sin placas: coste 0 congelado',
        );

        // Reaplicar la migración no falla ni duplica nada.
        final before = (await settingsOf(raw)).length;
        await DbSchema.onUpgrade(raw, 2, DbSchema.version);
        expect((await settingsOf(raw)).length, before);
        await raw.close();
      },
    );

    test(
      'v4 → v5 conserva los ajustes y el detalle de pintura antiguos',
      () async {
        final raw = await openOld(4, (db) async {
          await db.execute(settingsTable);
          for (final (key, value) in [
            ('margen_beneficio', 15.0),
            ('margen_seguridad', 15.0),
            ('coste_kwh', 0.0375),
            ('coste_hora_pintado', 8.0),
            ('coste_pintura_normal', 0.1),
            ('objetivo_beneficio', 4000.0),
          ]) {
            await db.insert('settings', {'key': key, 'value': value});
          }
          await db.execute(
            'CREATE TABLE orders (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'client_id INTEGER, name TEXT NOT NULL, price REAL NOT NULL, '
            'paid_amount REAL DEFAULT 0.0, date TEXT NOT NULL, '
            'status TEXT NOT NULL, is_painted INTEGER NOT NULL, notes TEXT, '
            'attempts REAL NOT NULL DEFAULT 1, '
            'paint_hours REAL NOT NULL DEFAULT 2, '
            'paint_colors REAL NOT NULL DEFAULT 0, cost_override REAL, '
            "paint_detail TEXT NOT NULL DEFAULT 'normal')",
          );
          await db.insert('orders', {
            'name': 'Pintado',
            'price': 50,
            'date': '2026-11-01',
            'status': 'Draft',
            'is_painted': 1,
            'paint_detail': 'many',
          });
        });
        await DbSchema.onUpgrade(raw, 4, DbSchema.version);
        await DbSchema.onOpen(raw);

        final values = await settingsOf(raw);
        expect(values['margen_beneficio'], 150);
        expect(values['objetivo_beneficio'], 4000, reason: 'se respeta');
        expect(values['coste_hora_pintado'], 8, reason: 'se respeta');
        expect(values['coste_kwh'], 0.0375, reason: 'obsoleta, se conserva');
        expect(values['precio_kwh'], 0.15, reason: 'ajuste nuevo');
        expect((await raw.query('orders')).single['name'], 'Pintado');
        await raw.close();
      },
    );

    test('v6 → v7 congela el coste de los pedidos cerrados', () async {
      final raw = await openOld(6, (db) async {
        await db.execute(settingsTable);
        await db.execute(
          'CREATE TABLE materials (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'name TEXT NOT NULL, color TEXT NOT NULL, type TEXT NOT NULL, '
          'cost_per_kg REAL NOT NULL, stock_g REAL NOT NULL)',
        );
        await db.insert('materials', {
          'name': 'PLA',
          'color': 'Negro',
          'type': 'filament',
          'cost_per_kg': 20.0,
          'stock_g': 500.0,
        });
        await db.execute(
          'CREATE TABLE orders (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'client_id INTEGER, name TEXT NOT NULL, price REAL NOT NULL, '
          'paid_amount REAL DEFAULT 0.0, date TEXT NOT NULL, '
          'status TEXT NOT NULL, is_painted INTEGER NOT NULL, notes TEXT, '
          'attempts REAL NOT NULL DEFAULT 1, paint_hours REAL NOT NULL '
          'DEFAULT 0, paint_colors REAL NOT NULL DEFAULT 0, cost_override '
          'REAL, paint_level INTEGER NOT NULL DEFAULT 1)',
        );
        await db.execute(
          'CREATE TABLE order_plates (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'order_id INTEGER NOT NULL, name TEXT NOT NULL, grams REAL NOT NULL, '
          'minutes REAL NOT NULL, material_id INTEGER NOT NULL, '
          "status TEXT DEFAULT 'Pending')",
        );
        for (final (name, status) in [
          ('Hecho', 'Completed'),
          ('Abierto', 'Draft'),
        ]) {
          final id = await db.insert('orders', {
            'name': name,
            'price': 30,
            'date': '2026-01-01',
            'status': status,
            'is_painted': 0,
          });
          await db.insert('order_plates', {
            'order_id': id,
            'name': 'A',
            'grams': 100.0,
            'minutes': 60.0,
            'material_id': 1,
          });
        }
      });
      await DbSchema.onUpgrade(raw, 6, DbSchema.version);

      final rows = {
        for (final r in await raw.query('orders'))
          r['name']: r['cost_override'],
      };
      expect(rows['Hecho'], closeTo(3.1375, 0.001));
      expect(
        rows['Abierto'],
        isNull,
        reason: 'los abiertos se siguen calculando',
      );
      await raw.close();
    });

    test('v7 → v8 retira los materiales «Histórico (Excel)» conservando '
        'el coste de los pedidos', () async {
      final raw = await openOld(7, (db) async {
        await db.execute(settingsTable);
        await db.execute(
          'CREATE TABLE materials (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'name TEXT NOT NULL, color TEXT NOT NULL, type TEXT NOT NULL, '
          'cost_per_kg REAL NOT NULL, stock_g REAL NOT NULL)',
        );
        for (final (name, type, price) in [
          ('Histórico (Excel)', 'filament', 10.0),
          ('Histórico (Excel)', 'resin', 30.0),
          ('PLA real', 'filament', 20.0),
        ]) {
          await db.insert('materials', {
            'name': name,
            'color': 'x',
            'type': type,
            'cost_per_kg': price,
            'stock_g': 0.0,
          });
        }
        await db.execute(
          'CREATE TABLE orders (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'client_id INTEGER, name TEXT NOT NULL, price REAL NOT NULL, '
          'paid_amount REAL DEFAULT 0.0, date TEXT NOT NULL, '
          'status TEXT NOT NULL, is_painted INTEGER NOT NULL, notes TEXT, '
          'attempts REAL NOT NULL DEFAULT 1, paint_hours REAL NOT NULL '
          'DEFAULT 0, paint_colors REAL NOT NULL DEFAULT 0, cost_override '
          'REAL, paint_level INTEGER NOT NULL DEFAULT 1)',
        );
        await db.execute(
          'CREATE TABLE order_plates (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'order_id INTEGER NOT NULL, name TEXT NOT NULL, grams REAL NOT NULL, '
          'minutes REAL NOT NULL, material_id INTEGER NOT NULL, '
          "status TEXT DEFAULT 'Pending')",
        );
        await db.execute(
          'CREATE TABLE order_waste (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'order_id INTEGER NOT NULL, material_id INTEGER NOT NULL, '
          'grams_wasted REAL NOT NULL, reason TEXT, date TEXT)',
        );
        // 1: borrador importado (material histórico, sin coste fijo);
        // 2: pedido con un material real.
        for (final (name, material) in [('Importado', 1), ('Real', 3)]) {
          final id = await db.insert('orders', {
            'name': name,
            'price': 30,
            'date': '2026-01-01',
            'status': 'Draft',
            'is_painted': 0,
          });
          await db.insert('order_plates', {
            'order_id': id,
            'name': 'A',
            'grams': 1000.0,
            'minutes': 0.0,
            'material_id': material,
          });
        }
        await db.insert('order_waste', {
          'order_id': 1,
          'material_id': 2,
          'grams_wasted': 50.0,
        });
      });
      await DbSchema.onUpgrade(raw, 7, DbSchema.version);

      final materials = await raw.query('materials');
      expect(materials.map((m) => m['name']), ['PLA real']);

      final orders = {
        for (final r in await raw.query('orders'))
          r['name']: r['cost_override'],
      };
      expect(
        orders['Importado'],
        isNotNull,
        reason: 'el coste histórico se conserva',
      );
      expect(orders['Importado'] as num, greaterThan(0));
      expect(orders['Real'], isNull);

      final plates = {
        for (final r in await raw.query('order_plates'))
          r['order_id']: r['material_id'],
      };
      expect(plates, {1: null, 2: 3});
      expect((await raw.query('order_waste')).single['material_id'], isNull);

      // La columna ya admite NULL en tablas nuevas y reconstruidas.
      await raw.insert('order_plates', {
        'order_id': 2,
        'name': 'B',
        'grams': 1.0,
        'minutes': 1.0,
      });
      await raw.close();
    });

    test('v8 → v9 añade is_personal sin tocar los pedidos', () async {
      final raw = await openOld(8, (db) async {
        await db.execute(
          'CREATE TABLE orders (id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'client_id INTEGER, name TEXT NOT NULL, price REAL NOT NULL, '
          'paid_amount REAL DEFAULT 0.0, date TEXT NOT NULL, '
          'status TEXT NOT NULL, is_painted INTEGER NOT NULL, notes TEXT)',
        );
        await db.insert('orders', {
          'name': 'Viejo',
          'price': 12.0,
          'date': '2026-01-01',
          'status': 'Draft',
          'is_painted': 0,
        });
      });
      await DbSchema.onUpgrade(raw, 8, DbSchema.version);
      final row = (await raw.query('orders')).single;
      expect(row['is_personal'], 0);
      expect(row['price'], 12.0);
      await raw.close();
    });
  });
}
