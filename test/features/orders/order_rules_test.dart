import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';
import 'package:nesherprints/features/orders/domain/order_rules.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

const _order = Order(
  name: 'Figura',
  price: 30,
  date: '2026-11-23',
  status: OrderStatus.draft,
);

const _plate = OrderPlate(name: 'A', grams: 100, minutes: 60, materialId: 1);

void main() {
  group('OrderRules.validateForm', () {
    test('un pedido correcto no tiene errores', () {
      expect(OrderRules.validateForm(_order, [_plate]), isEmpty);
    });

    test('un precio de 0 es válido (regalos y pruebas)', () {
      expect(
        OrderRules.validateForm(_order.copyWith(price: 0), [_plate]),
        isEmpty,
      );
    });

    test('rechaza cobrar más que el precio', () {
      final errors = OrderRules.validateForm(_order.copyWith(paidAmount: 40), [
        _plate,
      ]);
      expect(errors, ['Lo cobrado no puede superar el precio final.']);
      expect(
        OrderRules.validateForm(_order.copyWith(paidAmount: 30), [_plate]),
        isEmpty,
        reason: 'cobrar justo el precio vale',
      );
    });

    test('rechaza gramos y tiempos absurdos en una placa', () {
      const huge = OrderPlate(
        name: 'A',
        grams: 100000,
        minutes: 60,
        materialId: 1,
      );
      const endless = OrderPlate(
        name: 'A',
        grams: 100,
        minutes: 20000,
        materialId: 1,
      );
      expect(OrderRules.validateForm(_order, [huge]).single, contains('kg'));
      expect(
        OrderRules.validateForm(_order, [endless]).single,
        contains('10 días'),
      );
    });

    test('pide nombre, placas y material', () {
      final errors = OrderRules.validateForm(_order.copyWith(name: ' '), []);
      expect(errors, contains('Escribe el nombre del proyecto.'));
      expect(errors, contains('Añade al menos una placa.'));

      final noMaterial = OrderRules.validateForm(_order, [
        const OrderPlate(name: 'A', grams: 10, minutes: 1, materialId: null),
      ]);
      expect(noMaterial, ['La placa 1 no tiene material.']);
    });

    test('pide gramos positivos y rechaza tiempos o importes negativos', () {
      final errors = OrderRules.validateForm(
        _order.copyWith(price: -1, paidAmount: -2, attempts: 0),
        [
          const OrderPlate(name: 'A', grams: 0, minutes: 1, materialId: 1),
          const OrderPlate(name: 'B', grams: 5, minutes: -1, materialId: 1),
        ],
      );
      expect(errors, hasLength(5)); // precio, pagado, intentos + 2 placas
      expect(errors, contains('La placa 1 necesita gramos (más de 0).'));
      expect(errors, contains('La placa 2 tiene un tiempo negativo.'));
    });

    test('rechaza NaN e infinito', () {
      expect(
        OrderRules.validateOrder(_order.copyWith(price: double.nan)),
        isNotEmpty,
      );
      expect(
        OrderRules.validateOrder(_order.copyWith(price: double.infinity)),
        isNotEmpty,
      );
    });
  });

  group('OrderStatus', () {
    test('etiquetas en español y valores guardados en inglés', () {
      expect(OrderStatus.inProgress.label, 'En curso');
      expect(OrderStatus.inProgress.dbValue, 'In Progress');
      expect(OrderStatus.shipped.label, 'Enviado');
    });

    test('cambios rápidos permitidos', () {
      expect(
        OrderStatus.draft.quickChangeTargets,
        unorderedEquals([
          OrderStatus.reserved,
          OrderStatus.inProgress,
          OrderStatus.canceled,
        ]),
      );
      expect(OrderStatus.completed.quickChangeTargets, [OrderStatus.shipped]);
      expect(OrderStatus.shipped.quickChangeTargets, isEmpty);
      expect(
        OrderStatus.canceled.quickChangeTargets,
        contains(OrderStatus.draft),
        reason: 'un pedido cancelado se puede recuperar',
      );
    });

    test('Completado y Enviado no se eligen a mano', () {
      expect(OrderStatus.manualChoices, isNot(contains(OrderStatus.completed)));
      expect(OrderStatus.manualChoices, isNot(contains(OrderStatus.shipped)));
    });
  });
}
