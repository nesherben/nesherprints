import 'package:nesherprints/core/errors/app_exception.dart';
import 'package:nesherprints/features/orders/domain/order.dart';
import 'package:nesherprints/features/orders/domain/order_parts.dart';

/// Un pedido o una operación incumple una regla. El mensaje se puede mostrar
/// tal cual al usuario.
class OrderRuleException extends AppException {
  const OrderRuleException(super.message);
}

/// Reglas de validación de pedidos (puras, sin acceso a datos).
class OrderRules {
  OrderRules._();

  /// Errores del propio pedido (los comprueba también el repositorio).
  static List<String> validateOrder(Order order) => [
    if (order.name.trim().isEmpty) 'Escribe el nombre del proyecto.',
    if (!_isFinite(order.price) || order.price < 0)
      'El precio no puede ser negativo.',
    if (!_isFinite(order.paidAmount) || order.paidAmount < 0)
      'Lo pagado no puede ser negativo.',
    if (!_isFinite(order.attempts) || order.attempts <= 0)
      'Los intentos deben ser 1 o más.',
  ];

  /// Tope de gramos por placa: por encima casi seguro es un error al teclear.
  static const double maxPlateGrams = 5000;

  /// Tope de tiempo por placa (10 días).
  static const double maxPlateMinutes = 14400;

  /// Errores del formulario: el pedido y además sus placas.
  static List<String> validateForm(Order order, List<OrderPlate> plates) => [
    ...validateOrder(order),
    if (_isFinite(order.price) &&
        _isFinite(order.paidAmount) &&
        order.paidAmount > order.price + 0.005)
      'Lo cobrado no puede superar el precio final.',
    if (plates.isEmpty) 'Añade al menos una placa.',
    for (final (i, plate) in plates.indexed) ...[
      if (plate.materialId == null) 'La placa ${i + 1} no tiene material.',
      if (!_isFinite(plate.grams) || plate.grams <= 0)
        'La placa ${i + 1} necesita gramos (más de 0).',
      if (_isFinite(plate.grams) && plate.grams > maxPlateGrams)
        'La placa ${i + 1} supera ${maxPlateGrams ~/ 1000} kg: revisa los gramos.',
      if (!_isFinite(plate.minutes) || plate.minutes < 0)
        'La placa ${i + 1} tiene un tiempo negativo.',
      if (_isFinite(plate.minutes) && plate.minutes > maxPlateMinutes)
        'La placa ${i + 1} supera los 10 días: revisa el tiempo.',
    ],
  ];

  static bool _isFinite(double v) => !v.isNaN && !v.isInfinite;

  /// Lanza [OrderRuleException] si el pedido no es válido.
  static void requireValid(Order order) {
    final errors = validateOrder(order);
    if (errors.isNotEmpty) throw OrderRuleException(errors.first);
  }

  /// Coste fijo que debe conservar un pedido al guardarlo desde el formulario:
  /// solo los cerrados mantienen el congelado; uno abierto lo recalcula con
  /// sus placas (que al guardar ya tienen material) y se congela al completarlo.
  static double? costOverrideOnSave(Order? initial) =>
      (initial?.status.countsAsRevenue ?? false) ? initial?.costOverride : null;
}
