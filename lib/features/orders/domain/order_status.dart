/// Estado de un pedido. [dbValue] es el texto guardado en `orders.status`
/// (en inglés por compatibilidad) y también el que se muestra en la UI.
enum OrderStatus {
  draft('Draft'),
  reserved('Reserved'),
  inProgress('In Progress'),
  completed('Completed'),
  shipped('Shipped'),
  canceled('Canceled');

  const OrderStatus(this.dbValue);

  final String dbValue;

  String get label => dbValue;

  /// Valores desconocidos se tratan como borrador.
  static OrderStatus fromDb(String? value) => values.firstWhere(
    (s) => s.dbValue == value,
    orElse: () => OrderStatus.draft,
  );

  /// Estados que se pueden elegir a mano (formulario y cambio rápido).
  /// `completed` solo se alcanza con la acción "Completar".
  static const List<OrderStatus> manualChoices = [
    draft,
    reserved,
    inProgress,
    shipped,
    canceled,
  ];

  /// Pedido cerrado: el formulario se abre en solo lectura.
  bool get isLocked => this == completed || this == shipped;

  /// Se puede ejecutar "Completar" (resta stock y marca como pagado).
  bool get canComplete => !isLocked && this != canceled;

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
