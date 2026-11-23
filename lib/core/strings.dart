class AppStrings {
  // Navigation
  static const String all = 'Todos';
  static const String dashboard = 'Panel';
  static const String inventory = 'Inventario';
  static const String orders = 'Pedidos';
  static const String clients = 'Clientes';
  static const String admin = 'Administración';

  // General actions
  static const String cancel = 'Cancelar';
  static const String save = 'Guardar';
  static const String delete = 'Eliminar';
  static const String confirm = 'Confirmar';
  static const String saveSettings = 'Guardar Configuración';

  // Extras / Pieces
  static const String pieces = 'Piezas';
  static const String addPieces = 'Añadir Piezas';
  static const String addUnits = 'Unidades a añadir';
  static const String totalPriceOfUnits = 'Precio total de estas unidades (€)';
  static const String addExtra = 'Añadir Extra';
  static const String editExtra = 'Editar Extra';
  static const String unitsPerPackage = 'Unidades por paquete';
  static const String totalPricePackage = 'Precio total del paquete (€)';
  static const String apply = 'Aplicar';

  // Confirmation texts
  static const String confirmDeletionTitle = 'Confirmar eliminación';
  static String confirmDeletionMessage(String name) =>
      '¿Eliminar "$name"? Esta acción no se puede deshacer.';

  // Tooltips / small labels
  static const String edit = 'Editar';
  static const String addStock = 'Sumar unidades';
  static const String deleteTooltip = 'Eliminar';

  // Admin / Settings
  static const String settingsUpdated = 'Variables actualizadas correctamente';

  // Order form
  static const String newOrder = 'Nuevo Pedido';
  static const String editOrder = 'Editar Pedido';
  static const String saveOrder = 'Guardar Pedido';
  static const String blocked = 'BLOQUEADO';

  // Small generic
  static const String noExtrasDefined = 'No hay extras definidos.';
  // Order / Forms
  static const String nameLabel = 'Nombre';
  static const String clientOptional = 'Cliente (Opcional)';
  static const String unassigned = 'Sin asignar';
  static const String projectName = 'Nombre del Proyecto';
  static const String status = 'Estado';
  static const String newClient = 'Nuevo Cliente';
  static const String editClient = 'Editar Cliente';
  static const String optionalFields =
      'Todos los campos son opcionales. Rellena solo lo que sepas.';
  static const String clientNameLabel = 'Nombre / Alias';
  static const String clientPhoneLabel = 'Teléfono (WhatsApp)';
  static const String clientContactLabel = 'Email / Instagram';

  // Plates / Materials
  static const String platesConfigTitle = 'Configuración por Placas';
  static const String addPlate = 'Añadir Placa';
  static const String noPlates =
      'No hay placas. Añade una para empezar a calcular.';
  static const String gramsLabel = 'Gramos (g)';
  static const String timeLabel = 'Tiempo';

  // Extras UI
  static const String extrasTitle = 'Extras (llaveros, clickers, etc.)';

  // Materials
  static const String addMaterial = 'Añadir Material';
  static const String editMaterial = 'Editar Material';
  static const String materialTypeLabel = 'Tipo de Material';
  static const String materialTypeFilament = 'Filamento (Bobina)';
  static const String materialTypeResin = 'Resina (Tanque/Bote)';
  static const String materialNameLabel = 'Nombre/Marca';
  static const String materialColorLabel = 'Color';
  static const String materialCostPerKg = 'Coste por Kg (€)';
  static const String materialStockLabel = 'Stock (gramos/ml)';
  // Finanzas / Dashboard
  static const String financesTitle = 'Finanzas y Tiempos Extra';
  static const String totalPlatesAuto = 'Total Placas (Automático)';
  static const String paintServiceTitle = 'Servicio de Pintura';
  static const String paintHoursLabel = 'Horas Pintura';
  static const String costManufacture = 'Coste Fabricación';
  static const String suggestedPrice = 'Precio Sugerido';
  static const String finalPriceLabel = 'Precio Final (€)';
  static const String paidAdvanceLabel = 'Pagado / Adelanto';
  static const String grossLabel = 'Bruto';
  static const String netLabel = 'Neto';
  static const String noData = 'Sin datos';
  static const String billingHistoryTitle = 'Histórico de Facturación';
  static const String distributionTitle = 'Distribución de Pedidos';
  static const String completeFirstOrderHint =
      'Completa tu primer pedido para ver el gráfico.';

  // Misc
  static const String createNewClient = 'Crear nuevo cliente';
  static const String registerWaste = 'Registrar Pérdida';
  static const String nameColumn = 'Nombre';
}
