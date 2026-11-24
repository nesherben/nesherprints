import 'package:nesherprints/core/constants/app_constants.dart';
import 'package:nesherprints/core/database/db_schema.dart';
import 'package:nesherprints/core/utils/number_utils.dart';
import 'package:nesherprints/features/orders/domain/order_status.dart';

/// Pedido de impresión (fila de `orders`).
class Order {
  const Order({
    this.id,
    this.clientId,
    required this.name,
    required this.price,
    this.paidAmount = 0,
    required this.date,
    required this.status,
    this.isPainted = false,
    this.notes = '',
    this.attempts = 1,
    this.paintHours = 0,
    this.costOverride,
  });

  final int? id;
  final int? clientId;
  final String name;

  /// Precio final acordado con el cliente (€).
  final double price;

  /// Importe ya cobrado (€).
  final double paidAmount;

  /// Fecha de creación `YYYY-MM-DD`.
  final String date;
  final OrderStatus status;
  final bool isPainted;
  final String notes;

  /// Multiplicador de material y luz por impresiones falladas (1 = a la
  /// primera, 1,3 = un 30 % más).
  final double attempts;

  /// Horas de trabajo de pintura.
  final double paintHours;

  /// Coste real fijo. Solo lo tienen los pedidos importados del Excel con
  /// otra fórmula; si existe, sustituye al coste calculado.
  final double? costOverride;

  /// Lo que falta por cobrar (puede ser negativo si se cobró de más).
  double get pendingAmount => price - paidAmount;

  /// Pagado del todo o completado.
  bool get isSettled => status == OrderStatus.completed || pendingAmount <= 0;

  Order copyWith({
    String? name,
    double? price,
    double? paidAmount,
    OrderStatus? status,
    double? attempts,
  }) => Order(
    id: id,
    clientId: clientId,
    name: name ?? this.name,
    price: price ?? this.price,
    paidAmount: paidAmount ?? this.paidAmount,
    date: date,
    status: status ?? this.status,
    isPainted: isPainted,
    notes: notes,
    attempts: attempts ?? this.attempts,
    paintHours: paintHours,
    costOverride: costOverride,
  );

  factory Order.fromMap(Map<String, Object?> map) => Order(
    id: map[OrdersTable.id] as int?,
    clientId: map[OrdersTable.clientId] as int?,
    name: map[OrdersTable.orderName] as String? ?? '',
    price: asDouble(map[OrdersTable.price]),
    paidAmount: asDouble(map[OrdersTable.paidAmount]),
    date: map[OrdersTable.date] as String? ?? '',
    status: OrderStatus.fromDb(map[OrdersTable.status] as String?),
    isPainted: map[OrdersTable.isPainted] == 1,
    notes: map[OrdersTable.notes] as String? ?? '',
    attempts: asDouble(map[OrdersTable.attempts], fallback: 1),
    paintHours: asDouble(map[OrdersTable.paintHours]),
    costOverride: (map[OrdersTable.costOverride] as num?)?.toDouble(),
  );

  /// Columnas de `orders` (sin `id`).
  Map<String, Object?> toMap() => {
    OrdersTable.clientId: clientId,
    OrdersTable.orderName: name,
    OrdersTable.price: price,
    OrdersTable.paidAmount: paidAmount,
    OrdersTable.date: date,
    OrdersTable.status: status.dbValue,
    OrdersTable.isPainted: isPainted ? 1 : 0,
    OrdersTable.notes: notes,
    OrdersTable.attempts: attempts,
    OrdersTable.paintHours: paintHours,
    OrdersTable.costOverride: costOverride,
  };
}

/// Pedido con datos agregados para el listado y el panel
/// (resultado de `OrderRepository.getAllWithDetails`).
class OrderSummary {
  const OrderSummary({
    required this.order,
    this.clientName,
    this.materialCost = 0,
    this.theoreticalGrams,
    this.wastedGrams = 0,
    this.plateNames,
    this.platesCount = 0,
  });

  final Order order;
  final String? clientName;

  /// Coste de material de las placas (€).
  final double materialCost;

  /// Suma de gramos de las placas (`null` si no tiene placas).
  final double? theoreticalGrams;

  /// Gramos perdidos registrados como merma.
  final double wastedGrams;

  /// Nombres de las placas separados por comas.
  final String? plateNames;
  final int platesCount;

  int get id => order.id!;

  /// Merma acumulada en % sobre el peso teórico (puede superar el 100 %).
  /// Sin peso teórico se divide entre 1 g.
  double get wasteRatePercent {
    var theoretical = theoreticalGrams ?? 1.0;
    if (theoretical == 0) theoretical = 1.0;
    return wastedGrams / theoretical * 100;
  }

  WasteSeverity get wasteSeverity => WasteSeverity.of(wasteRatePercent);

  factory OrderSummary.fromMap(Map<String, Object?> map) => OrderSummary(
    order: Order.fromMap(map),
    clientName: map['client_name'] as String?,
    materialCost: asDouble(map['material_cost']),
    theoreticalGrams: (map['total_theoretical_grams'] as num?)?.toDouble(),
    wastedGrams: asDouble(map['total_wasted_grams']),
    plateNames: map['plates_names'] as String?,
    platesCount: (map['plates_count'] as int?) ?? 0,
  );
}

/// Gravedad de la merma de un pedido.
enum WasteSeverity {
  low,
  medium,
  high;

  static WasteSeverity of(double percent) {
    if (percent > WasteRules.highPercent) return high;
    if (percent > WasteRules.mediumPercent) return medium;
    return low;
  }
}
