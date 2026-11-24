import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/features/extras/data/extras_repository.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';
import 'package:nesherprints/features/inventory/data/material_repository.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/orders/data/order_repository.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_rules.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Reglas que el stock y los pedidos cumplen siempre (ver docs/SPEC.md §5).
/// Cada test nació de un fallo confirmado en la revisión de nov-2026.
void main() {
  late AppDatabase db;
  late OrderRepository orders;
  late MaterialRepository materials;
  late ExtrasRepository extras;

  setUp(() {
    db = AppDatabase.inMemory();
    orders = OrderRepository(db);
    materials = MaterialRepository(db);
    extras = ExtrasRepository(db);
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

  Future<double> stockOf(int id) async =>
      (await materials.getAll()).firstWhere((m) => m.id == id).stockGrams;

  Future<int> orderWithPlate(int matId, {double grams = 100}) => orders.create(
    const Order(
      name: 'Figura',
      price: 30,
      date: '2026-11-23',
      status: OrderStatus.inProgress,
    ),
    plates: [
      OrderPlate(name: 'A', grams: grams, minutes: 60, materialId: matId),
    ],
  );

  Future<int> keychain({int stock = 10}) =>
      extras.save(Extra(name: 'Anilla', unitPrice: 0.5, stock: stock));

  Future<int> extraStock(int id) async =>
      (await extras.getAll()).firstWhere((e) => e.id == id).stock;

  /// Pedido mínimo válido. `withId` para actualizar uno existente.
  Order draft({int? withId}) => Order(
    id: withId,
    name: 'P',
    price: 1,
    date: '2026-11-23',
    status: OrderStatus.draft,
  );

  group('Completar', () {
    test('completar un pedido ya completado no descuenta otra vez', () async {
      final mat = await pla();
      final id = await orderWithPlate(mat);

      await orders.complete(id);
      expect(await stockOf(mat), 900);

      await orders.complete(id);
      expect(
        await stockOf(mat),
        900,
        reason: 'el material se descuenta una vez',
      );
    });

    test('un pedido completado no se puede reabrir', () async {
      final mat = await pla();
      final id = await orderWithPlate(mat);
      await orders.complete(id);

      await expectLater(
        orders.updateStatus(id, OrderStatus.inProgress),
        throwsA(isA<OrderRuleException>()),
      );
      expect(await stockOf(mat), 900);
    });

    test(
      'merma + completar: el material de la placa sale una sola vez',
      () async {
        final mat = await pla();
        final id = await orderWithPlate(mat, grams: 200);

        // Fallo al 25 %: se pierden 50 g.
        await orders.addWaste(
          orderId: id,
          materialId: mat,
          grams: 50,
          reason: 'se despegó',
        );
        expect(await stockOf(mat), 950);

        await orders.complete(id);

        // La placa pesa 200 g: 50 g ya salieron como merma, quedan 150 g.
        expect(await stockOf(mat), 800);
      },
    );

    test('una merma mayor que la placa no deja stock a favor', () async {
      final mat = await pla();
      final id = await orderWithPlate(mat, grams: 100);
      await orders.addWaste(
        orderId: id,
        materialId: mat,
        grams: 150,
        reason: 'x',
      );
      await orders.complete(id);
      expect(await stockOf(mat), 850, reason: 'solo sale la merma');
    });

    test('un pedido cancelado no se puede completar', () async {
      final mat = await pla();
      final id = await orderWithPlate(mat);
      await orders.updateStatus(id, OrderStatus.canceled);
      await expectLater(
        orders.complete(id),
        throwsA(isA<OrderRuleException>()),
      );
      expect(await stockOf(mat), 1000);
    });
  });

  group('Cambio de estado', () {
    test('no se puede pasar a Completado ni Enviado sin Completar', () async {
      final mat = await pla();
      final id = await orderWithPlate(mat);
      await expectLater(
        orders.updateStatus(id, OrderStatus.completed),
        throwsA(isA<OrderRuleException>()),
      );
      await expectLater(
        orders.updateStatus(id, OrderStatus.shipped),
        throwsA(isA<OrderRuleException>()),
        reason: 'enviar sin completar dejaría el stock sin descontar',
      );
    });

    test('Completado → Enviado es posible y no toca el stock', () async {
      final mat = await pla();
      final id = await orderWithPlate(mat);
      await orders.complete(id);
      await orders.updateStatus(id, OrderStatus.shipped);
      expect(
        (await orders.getAllWithDetails()).single.order.status,
        OrderStatus.shipped,
      );
      expect(await stockOf(mat), 900);
    });

    test('un pedido abierto cambia entre estados abiertos', () async {
      final mat = await pla();
      final id = await orderWithPlate(mat);
      for (final s in [
        OrderStatus.draft,
        OrderStatus.reserved,
        OrderStatus.canceled,
        OrderStatus.inProgress,
      ]) {
        await orders.updateStatus(id, s);
        expect((await orders.getAllWithDetails()).single.order.status, s);
      }
    });

    test('un pedido cerrado no se puede editar', () async {
      final mat = await pla();
      final id = await orderWithPlate(mat);
      await orders.complete(id);
      await expectLater(
        orders.update(draft(withId: id)),
        throwsA(isA<OrderRuleException>()),
      );
    });
  });

  group('Borrar pedido', () {
    test('no deja placas huérfanas', () async {
      final mat = await pla();
      final id = await orderWithPlate(mat);

      await orders.delete(id);

      expect(await orders.getPlates(id), isEmpty);
    });

    test('no deja mermas huérfanas', () async {
      final mat = await pla();
      final id = await orderWithPlate(mat);
      await orders.addWaste(
        orderId: id,
        materialId: mat,
        grams: 10,
        reason: 'x',
      );

      await orders.delete(id);

      expect(await orders.getAllWaste(), isEmpty);
    });

    test('no repone el material (ya se gastó) pero sí las piezas', () async {
      final mat = await pla();
      final ex = await keychain(stock: 10);
      final id = await orders.create(
        const Order(
          name: 'P',
          price: 1,
          date: '2026-11-23',
          status: OrderStatus.inProgress,
        ),
        plates: [
          OrderPlate(name: 'A', grams: 100, minutes: 1, materialId: mat),
        ],
        extras: [OrderExtraLine(extraId: ex, quantity: 4)],
      );
      await orders.complete(id);
      expect(await stockOf(mat), 900);
      expect(await extraStock(ex), 6);

      await orders.delete(id);

      expect(await stockOf(mat), 900);
      expect(await extraStock(ex), 10);
    });
  });

  group('Piezas extra', () {
    test('sumar stock con datos de pantalla viejos no pisa cambios', () async {
      final id = await keychain(stock: 10);
      final stale = (await extras.getAll()).single; // la pantalla ve 10

      // Mientras tanto, un pedido gasta 3 piezas.
      await orders.create(
        draft(),
        plates: const [],
        extras: [OrderExtraLine(extraId: id, quantity: 3)],
      );
      expect(await extraStock(id), 7);

      await extras.addStock(stale.id!, units: 5, totalPrice: 2.5);

      expect(await extraStock(id), 12, reason: '7 + 5, no 10 + 5');
    });

    test(
      'editar un pedido no cambia el precio unitario ya registrado',
      () async {
        final id = await keychain();
        final orderId = await orders.create(
          draft(),
          plates: const [],
          extras: [OrderExtraLine(extraId: id, quantity: 2)],
        );
        // La pieza sube de precio después.
        await extras.save(
          Extra(id: id, name: 'Anilla', unitPrice: 1.0, stock: 8),
        );

        // Se edita el pedido dejando las mismas piezas.
        await orders.update(
          draft(withId: orderId),
          extras: [OrderExtraLine(extraId: id, quantity: 2)],
        );

        final lines = await orders.getExtras(orderId);
        expect(lines.single.unitPrice, 0.5);
      },
    );

    test('una pieza nueva en un pedido editado usa el precio actual', () async {
      final a = await keychain();
      final b = await extras.save(
        const Extra(name: 'Imán', unitPrice: 0.2, stock: 20),
      );
      final orderId = await orders.create(
        draft(),
        plates: const [],
        extras: [OrderExtraLine(extraId: a, quantity: 1)],
      );

      await orders.update(
        draft(withId: orderId),
        extras: [
          OrderExtraLine(extraId: a, quantity: 1),
          OrderExtraLine(extraId: b, quantity: 3),
        ],
      );

      final prices = {
        for (final l in await orders.getExtras(orderId)) l.extraId: l.unitPrice,
      };
      expect(prices, {a: 0.5, b: 0.2});
      expect(await extraStock(a), 9);
      expect(await extraStock(b), 17);
    });

    test('el precio medio no pondera con stock negativo', () {
      // Stock −3 a 0,5 €; se compran 10 uds por 8 €.
      expect(
        ExtraPricing.weightedUnitPrice(
          currentStock: -3,
          currentUnitPrice: 0.5,
          addedUnits: 10,
          addedTotal: 8,
        ),
        closeTo(0.8, 1e-9),
      );
    });

    test('sumar stock a una pieza que no existe avisa', () async {
      await expectLater(
        extras.addStock(999, units: 1, totalPrice: 1),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Validación en el repositorio', () {
    test(
      'rechaza pedidos sin nombre, importes negativos o sin intentos',
      () async {
        for (final bad in [
          draft().copyWith(name: '  '),
          draft().copyWith(price: -1),
          draft().copyWith(paidAmount: -5),
          draft().copyWith(attempts: 0),
        ]) {
          await expectLater(
            orders.create(bad, plates: const []),
            throwsA(isA<OrderRuleException>()),
          );
        }
        expect(await orders.getAllWithDetails(), isEmpty);
      },
    );

    test('rechaza mermas de 0 g', () async {
      final mat = await pla();
      final id = await orderWithPlate(mat);
      await expectLater(
        orders.addWaste(orderId: id, materialId: mat, grams: 0, reason: ''),
        throwsA(isA<OrderRuleException>()),
      );
      expect(await orders.getAllWaste(), isEmpty);
    });

    test('un pedido nuevo no puede nacer completado', () async {
      await expectLater(
        orders.create(
          draft().copyWith(status: OrderStatus.completed),
          plates: const [],
        ),
        throwsA(isA<OrderRuleException>()),
      );
    });
  });

  group('Editar placas y piezas', () {
    test('una lista vacía las borra; null no las toca', () async {
      final mat = await pla();
      final ex = await keychain(stock: 10);
      final id = await orders.create(
        draft(),
        plates: [OrderPlate(name: 'A', grams: 10, minutes: 1, materialId: mat)],
        extras: [OrderExtraLine(extraId: ex, quantity: 2)],
      );

      await orders.update(draft(withId: id));
      expect(await orders.getPlates(id), hasLength(1));
      expect(await orders.getExtras(id), hasLength(1));

      await orders.update(
        draft(withId: id),
        plates: const [],
        extras: const [],
      );
      expect(await orders.getPlates(id), isEmpty);
      expect(await orders.getExtras(id), isEmpty);
      expect(await extraStock(ex), 10, reason: 'las piezas vuelven al stock');
    });
  });

  test('K1: completar congela el coste y no cambia si sube el €/kg', () async {
    final mat = await pla();
    final id = await orderWithPlate(mat, grams: 100);
    await orders.complete(id);

    Future<double?> frozen() async => (await orders.getAllWithDetails())
        .firstWhere((o) => o.id == id)
        .order
        .costOverride;

    final cost = await frozen();
    // 100 g × 20 €/kg = 2 € de material + máquina (1 h) + 1 placa.
    expect(cost, closeTo(2 + 0.1375 + 1, 0.001));

    final material = (await materials.getAll()).single;
    await materials.save(
      PrintMaterial(
        id: material.id,
        kind: material.kind,
        name: material.name,
        color: material.color,
        costPerKg: 99,
        stockGrams: material.stockGrams,
      ),
    );
    expect(await frozen(), cost);
  });

  test('K4: una pieza eliminada del catálogo se conserva al editar', () async {
    final mat = await pla();
    final piece = await keychain(stock: 10);
    final id = await orders.create(
      const Order(
        name: 'Con pieza',
        price: 30,
        date: '2026-11-23',
        status: OrderStatus.inProgress,
      ),
      plates: [OrderPlate(name: 'A', grams: 50, minutes: 60, materialId: mat)],
      extras: [OrderExtraLine(extraId: piece, quantity: 2)],
    );
    await extras.delete(piece);

    await orders.update(
      (await orders.getAllWithDetails()).firstWhere((o) => o.id == id).order,
      extras: [OrderExtraLine(extraId: piece, quantity: 2)],
    );

    final lines = await orders.getExtras(id);
    expect(lines.single.extraId, piece);
    expect(lines.single.unitPrice, 0.5);
  });
}
