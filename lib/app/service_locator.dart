import 'package:flutter/foundation.dart';

import 'package:nesherprints/core/database/app_database.dart';
import 'package:nesherprints/features/clients/data/client_repository.dart';
import 'package:nesherprints/features/extras/data/extras_repository.dart';
import 'package:nesherprints/features/inventory/data/color_library_repository.dart';
import 'package:nesherprints/features/inventory/data/material_repository.dart';
import 'package:nesherprints/features/orders/data/order_repository.dart';
import 'package:nesherprints/features/settings/data/settings_repository.dart';

/// Repositorios únicos de la app, sobre la base de datos real.
///
/// Los tests de repositorio crean los suyos con `AppDatabase.inMemory()`; los
/// tests de pantalla usan [useDatabase] para que las pantallas reales trabajen
/// sobre una base de datos en memoria.
class ServiceLocator {
  ServiceLocator._();

  static OrderRepository orders = OrderRepository(AppDatabase.instance);
  static MaterialRepository materials = MaterialRepository(
    AppDatabase.instance,
  );
  static ColorLibraryRepository colors = ColorLibraryRepository(
    AppDatabase.instance,
  );
  static ClientRepository clients = ClientRepository(AppDatabase.instance);
  static ExtrasRepository extras = ExtrasRepository(AppDatabase.instance);
  static SettingsRepository settings = SettingsRepository(AppDatabase.instance);

  /// Solo para tests: apunta todos los repositorios a [db].
  @visibleForTesting
  static void useDatabase(AppDatabase db) {
    orders = OrderRepository(db);
    materials = MaterialRepository(db);
    colors = ColorLibraryRepository(db);
    clients = ClientRepository(db);
    extras = ExtrasRepository(db);
    settings = SettingsRepository(db);
  }
}
