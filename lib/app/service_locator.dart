import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/features/clients/data/client_repository.dart';
import 'package:nesherprints/features/extras/data/extras_repository.dart';
import 'package:nesherprints/features/inventory/data/material_repository.dart';
import 'package:nesherprints/features/orders/data/order_repository.dart';
import 'package:nesherprints/features/settings/data/settings_repository.dart';

/// Repositorios únicos de la app, sobre la base de datos real.
///
/// Los tests no lo usan: crean los repositorios con `AppDatabase.inMemory()`.
class ServiceLocator {
  ServiceLocator._();

  static final AppDatabase _db = AppDatabase.instance;

  static final OrderRepository orders = OrderRepository(_db);
  static final MaterialRepository materials = MaterialRepository(_db);
  static final ClientRepository clients = ClientRepository(_db);
  static final ExtrasRepository extras = ExtrasRepository(_db);
  static final SettingsRepository settings = SettingsRepository(_db);
}
