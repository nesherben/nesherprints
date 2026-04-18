import 'package:nesherprints/data/repositories/order_repository.dart';
import 'package:nesherprints/data/repositories/material_repository.dart';
import 'package:nesherprints/data/repositories/client_repository.dart';
import 'package:nesherprints/data/repositories/settings_repository.dart';

/// Service Locator: Proporciona instancias singleton de todos los repositorios
/// Acceso global desde cualquier parte del app sin duplicación de instancias
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  late final OrderRepository _orderRepository;
  late final MaterialRepository _materialRepository;
  late final ClientRepository _clientRepository;
  late final SettingsRepository _settingsRepository;

  ServiceLocator._internal() {
    _orderRepository = OrderRepository();
    _materialRepository = MaterialRepository();
    _clientRepository = ClientRepository();
    _settingsRepository = SettingsRepository();
  }

  factory ServiceLocator() {
    return _instance;
  }

  // Acceso a través de propiedades estáticas para simplificar uso
  static OrderRepository get orderRepo => _instance._orderRepository;
  static MaterialRepository get materialRepo => _instance._materialRepository;
  static ClientRepository get clientRepo => _instance._clientRepository;
  static SettingsRepository get settingsRepo => _instance._settingsRepository;
}
