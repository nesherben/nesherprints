import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/app/global_search.dart';
import 'package:nesherprints/features/clients/domain/client.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

void main() {
  final orders = [
    const OrderSummary(
      order: Order(
        id: 7,
        name: 'Dragón rojo',
        price: 10,
        date: '2026-01-01',
        status: OrderStatus.draft,
      ),
      clientName: 'Ana',
    ),
    const OrderSummary(
      order: Order(
        id: 8,
        name: 'Llavero',
        price: 5,
        date: '2026-01-02',
        status: OrderStatus.completed,
      ),
    ),
  ];
  const clients = [Client(id: 1, name: 'Ana Rojas', phone: '600111222')];
  const extras = [Extra(id: 2, name: 'Llavero metálico', unitPrice: 0.5)];
  const materials = [
    PrintMaterial(
      id: 3,
      kind: MaterialKind.filament,
      name: 'eSun PLA+',
      color: 'Rojo',
      costPerKg: 18,
      stockGrams: 0,
    ),
  ];

  List<SearchHit> run(String q) => GlobalSearch.search(
    q,
    orders: orders,
    clients: clients,
    extras: extras,
    materials: materials,
  );

  test('sin texto no hay resultados', () {
    expect(run('  '), isEmpty);
  });

  test('busca en pedidos, clientes, piezas y materiales', () {
    final hits = run('rojo');
    expect(hits.map((h) => h.kind).toSet(), {
      SearchKind.order,
      SearchKind.material,
    });
    final all = run('llavero');
    expect(all.map((h) => h.kind), [SearchKind.order, SearchKind.extra]);
  });

  test('encuentra por número de pedido, cliente y teléfono', () {
    expect(run('#8').single.id, 8);
    expect(run('ana').map((h) => h.kind), [
      SearchKind.order,
      SearchKind.client,
    ]);
    expect(run('60011').single.kind, SearchKind.client);
  });

  test('lo que empieza por el texto va antes que lo que lo contiene', () {
    final hits = run('rojas');
    expect(hits.single.title, 'Ana Rojas');
    final byStart = GlobalSearch.search(
      'ro',
      orders: const [],
      clients: const [],
      extras: const [],
      materials: materials,
    );
    expect(
      byStart.first.kind,
      SearchKind.material,
      reason: 'Rojo empieza por ro',
    );
  });
}
