// Centralized constants for the NesherPrints application
// This file contains all magic strings, enums, and configuration values

// ==================== ORDER STATUS ====================
class OrderStatus {
  static const String draft = 'Draft';
  static const String reserved = 'Reserved';
  static const String inProgress = 'In Progress';
  static const String completed = 'Completed';
  static const String shipped = 'Shipped';
  static const String canceled = 'Canceled';
  static const String pending = 'Pending';

  static const List<String> all = [
    draft,
    reserved,
    inProgress,
    completed,
    shipped,
    canceled,
  ];
}

// ==================== MATERIAL TYPES ====================
class MaterialTypes {
  static const String pla = 'PLA';
  static const String abs = 'ABS';
  static const String petg = 'PETG';
  static const String nylon = 'Nylon';
  static const String tpu = 'TPU';

  static const List<String> all = [pla, abs, petg, nylon, tpu];
}

// ==================== FINANCE SETTINGS ====================
class FinanceDefaults {
  static const double defaultBenefitMargin = 45.0;
  static const double defaultPaintingCost = 15.0;
  static const double defaultMinimumWasteKg = 0.05;
}

// ==================== DATABASE TABLES ====================
class DbTables {
  static const String orders = 'orders';
  static const String orderItems = 'order_items';
  static const String orderWaste = 'order_waste';
  static const String orderPlates = 'order_plates';
  static const String materials = 'materials';
  static const String clients = 'clients';
  static const String settings = 'settings';
  static const String extras = 'extras';
  static const String orderExtras = 'order_extras';
}

// ==================== DATABASE COLUMNS ====================
class DbColumns {
  // Orders
  static const String orderId = 'id';
  static const String orderName = 'name';
  static const String orderClientId = 'client_id';
  static const String orderForeignId = 'order_id';
  static const String orderStatus = 'status';
  static const String orderPrice = 'price';
  static const String orderPaidAmount = 'paid_amount';
  static const String orderIsPainted = 'is_painted';
  static const String orderCreatedAt = 'created_at';
  static const String orderUpdatedAt = 'updated_at';

  // Materials
  static const String materialId = 'id';
  static const String materialForeignId = 'material_id';
  static const String materialName = 'name';
  static const String materialType = 'type';
  static const String materialCostPerKg = 'cost_per_kg';
  static const String materialDensity = 'density';

  // Order plates
  static const String plateId = 'id';
  static const String plateOrderId = 'order_id';
  static const String plateName = 'name';
  static const String plateGrams = 'grams';
  static const String plateMinutes = 'minutes';
  static const String plateMaterialId = 'material_id';
  static const String plateStatus = 'status';

  // Clients
  static const String clientId = 'id';
  static const String clientName = 'name';
  static const String clientEmail = 'email';
  static const String clientPhone = 'phone';

  // Settings
  static const String settingKey = 'key';
  static const String settingValue = 'value';
}

// ==================== SETTINGS KEYS ====================
class SettingKeys {
  static const String margenBeneficio = 'margen_beneficio';
  static const String costeHoraPintado = 'coste_hora_pintado';
  static const String costePlacaExtra = 'coste_placa_extra';
  static const String minimoMermaPorcentaje = 'minimo_merma_porcentaje';
}

// ==================== UI STRINGS ====================
class UiStrings {
  static const String all = 'Todos';

  // Navigation
  static const String orders = 'Pedidos';
  static const String clients = 'Clientes';
  static const String inventory = 'Inventario';
  static const String pieces = 'Piezas';
  static const String admin = 'Administración';
  static const String dashboard = 'Panel';

  // Actions
  static const String add = 'Añadir';
  static const String edit = 'Editar';
  static const String delete = 'Eliminar';
  static const String save = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String confirm = 'Confirmar';
  static const String close = 'Cerrar';

  // Order actions
  static const String newOrder = 'Nuevo Pedido';
  static const String completeOrder = 'Completar Pedido';
  static const String recordWaste = 'Registrar Pérdida';
  static const String deleteOrder = 'Eliminar Pedido';
}

// ==================== VALIDATION ====================
class ValidationRules {
  static const int minNameLength = 3;
  static const int maxNameLength = 100;
  static const double minPrice = 0.01;
  static const double maxPrice = 99999.99;
  static const int minPhoneLength = 6;
}

// ==================== DATE/TIME FORMATS ====================
class DateFormats {
  static const String dateOnly = 'yyyy-MM-dd';
  static const String dateTime = 'yyyy-MM-dd HH:mm';
  static const String dateTimeSeconds = 'yyyy-MM-dd HH:mm:ss';
}
