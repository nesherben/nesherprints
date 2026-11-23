import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/features/extras/data/extras_repository.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';
import 'package:nesherprints/features/inventory/data/material_repository.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/orders/data/order_repository.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Reglas que el stock y los pedidos DEBERÍAN cumplir siempre.
///
/// Cada test describe el comportamiento correcto. Si falla, el fallo está
/// confirmado (ver docs/REVISION_2026-11.md).
/// Fallo confirmado y sin arreglar: se omite hasta que se corrija. Al
/// arreglarlo, cambiar `bugTest` por `test` y la prueba pasa a vigilarlo.
void bugTest(String name, dynamic Function() body) =>
    test(name, body, skip: 'bug confirmado, ver docs/REVISION_2026-11.md');

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

  group('Completar', () {
    bugTest(
      'completar un pedido ya completado no descuenta otra vez',
      () async {
        final mat = await pla();
        final id = await orderWithPlate(mat);

        await orders.complete(id);
        expect(await stockOf(mat), 900);

        // Camino real: el menú rápido permite salir de Completed.
        await orders.updateStatus(id, OrderStatus.inProgress);
        await orders.complete(id);

        expect(
          await stockOf(mat),
          900,
          reason: 'el material se descuenta una vez',
        );
      },
    );

    bugTest(
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
  });

  group('Borrar pedido', () {
    bugTest('no deja placas huérfanas', () async {
      final mat = await pla();
      final id = await orderWithPlate(mat);

      await orders.delete(id);

      expect(await orders.getPlates(id), isEmpty);
    });

    bugTest('no deja mermas huérfanas', () async {
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
  });

  group('Piezas extra', () {
    Future<int> keychain({int stock = 10}) =>
        extras.save(Extra(name: 'Anilla', unitPrice: 0.5, stock: stock));

    Future<int> extraStock(int id) async =>
        (await extras.getAll()).firstWhere((e) => e.id == id).stock;

    bugTest(
      'sumar stock con datos de pantalla viejos no pisa cambios',
      () async {
        final id = await keychain(stock: 10);
        final stale = (await extras.getAll()).single; // la pantalla ve 10

        // Mientras tanto, un pedido gasta 3 piezas.
        await orders.create(
          const Order(
            name: 'P',
            price: 1,
            date: '2026-11-23',
            status: OrderStatus.draft,
          ),
          plates: const [],
          extras: [OrderExtraLine(extraId: id, quantity: 3)],
        );
        expect(await extraStock(id), 7);

        await extras.addStock(stale, units: 5, totalPrice: 2.5);

        expect(await extraStock(id), 12, reason: '7 + 5, no 10 + 5');
      },
    );

    bugTest(
      'editar un pedido no cambia el precio unitario ya registrado',
      () async {
        final id = await keychain();
        final orderId = await orders.create(
          const Order(
            name: 'P',
            price: 1,
            date: '2026-11-23',
            status: OrderStatus.draft,
          ),
          plates: const [],
          extras: [OrderExtraLine(extraId: id, quantity: 2)],
        );
        // La pieza sube de precio después.
        await extras.save(
          Extra(id: id, name: 'Anilla', unitPrice: 1.0, stock: 8),
        );

        // Se edita el pedido dejando las mismas piezas.
        await orders.update(
          const Order(
            id: 1,
            name: 'P',
            price: 1,
            date: '2026-11-23',
            status: OrderStatus.draft,
          ),
          extras: [OrderExtraLine(extraId: id, quantity: 2)],
        );

        final raw = await (await db.database).query(OrderExtrasTable.name);
        expect(orderId, 1);
        expect(
          (raw.single[OrderExtrasTable.unitPrice] as num).toDouble(),
          0.5,
          reason: 'el precio registrado al crear el pedido se conserva',
        );
      },
    );

    bugTest('el precio medio no pondera con stock negativo', () {
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
  });
}
