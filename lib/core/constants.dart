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
}

// ==================== FINANCE SETTINGS ====================
class FinanceDefaults {
  static const double defaultBenefitMargin = 45.0;
  static const double defaultPaintingCost = 15.0;
  static const double defaultPlateExtraCost = 2.5;
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

  // Materials
  static const String materialId = 'id';
  static const String materialForeignId = 'material_id';
  static const String materialName = 'name';
  static const String materialType = 'type';
  static const String materialCostPerKg = 'cost_per_kg';

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
}
