/// Estado de un pedido. [dbValue] es el texto guardado en `orders.status`
/// (en inglés por compatibilidad: no cambiar sin migrar); [label] es lo que
/// se muestra en la interfaz.
enum OrderStatus {
  draft('Draft', 'Borrador'),
  reserved('Reserved', 'Reservado'),
  inProgress('In Progress', 'En curso'),
  completed('Completed', 'Completado'),
  shipped('Shipped', 'Enviado'),
  canceled('Canceled', 'Cancelado');

  const OrderStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  /// Valores desconocidos se tratan como borrador.
  static OrderStatus fromDb(String? value) => values.firstWhere(
    (s) => s.dbValue == value,
    orElse: () => OrderStatus.draft,
  );

  /// Estados que se pueden elegir a mano en el formulario de un pedido abierto.
  /// `completed` solo se alcanza con la acción "Completar" (descuenta
  /// material) y `shipped` solo desde `completed`.
  static const List<OrderStatus> manualChoices = [
    draft,
    reserved,
    inProgress,
    canceled,
  ];

  /// Pedido cerrado: el formulario se abre en solo lectura y no se puede
  /// reabrir (el material ya está descontado).
  bool get isLocked => this == completed || this == shipped;

  /// Se puede ejecutar "Completar" (resta stock y marca como pagado).
  bool get canComplete => !isLocked && this != canceled;

  /// Estados a los que se puede pasar con el cambio rápido de la tabla.
  List<OrderStatus> get quickChangeTargets => switch (this) {
    completed => const [shipped],
    shipped => const [],
    _ => [
      for (final s in manualChoices)
        if (s != this) s,
    ],
  };

  /// Cuenta como ingreso en el panel.
  bool get countsAsRevenue => this == completed || this == shipped;

  /// Genera deuda pendiente de cobro en el panel.
  bool get countsAsReceivable => this != draft && this != canceled;
}

/// Estado de una placa. [dbValue] es el texto guardado en `order_plates.status`.
enum PlateStatus {
  pending('Pending'),
  success('Success'),
  failed('Failed');

  const PlateStatus(this.dbValue);

  final String dbValue;

  static PlateStatus fromDb(String? value) => values.firstWhere(
    (s) => s.dbValue == value,
    orElse: () => PlateStatus.pending,
  );
}
