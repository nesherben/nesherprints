/// Todos los textos visibles de la app (español).
///
/// Regla: ningún widget escribe literales de UI; se añaden aquí, en la
/// sección de su pantalla.
class AppStrings {
  AppStrings._();

  // ==================== APP / NAVEGACIÓN ====================
  static const appTitle = 'NesherPrints ERP';
  static const navDashboard = 'Panel';
  static const navInventory = 'Inventario';
  static const navExtras = 'Piezas';
  static const navOrders = 'Pedidos';
  static const navClients = 'Clientes';
  static const navSettings = 'Administración';
  static const newOrder = 'Nuevo Pedido';

  // ==================== GENÉRICOS ====================
  static const all = 'Todos';
  static const cancel = 'Cancelar';
  static const save = 'Guardar';
  static const delete = 'Eliminar';
  static const edit = 'Editar';
  static const apply = 'Aplicar';
  static const name = 'Nombre';
  static const noData = 'Sin datos';
  static const confirmDeletionTitle = 'Confirmar eliminación';
  static String confirmDeletionMessage(String name) =>
      '¿Eliminar "$name"? Esta acción no se puede deshacer.';

  // ==================== PANEL (DASHBOARD) ====================
  static const billingHistoryTitle = 'Histórico de Facturación';
  static const dashboardSubtitle =
      'Análisis de ingresos brutos, beneficios netos y proyecciones';
  static const kpiGrossRevenue = 'Ingresos Brutos';
  static const kpiNetProfit = 'Beneficio Neto (Real)';
  static const kpiPendingCollection = 'Pendiente de Cobro';
  static const grossLabel = 'Bruto';
  static const netLabel = 'Neto';
  static const distributionTitle = 'Distribución de Pedidos';
  static const completeFirstOrderHint =
      'Completa tu primer pedido para ver el gráfico.';
  static String statusLegend(String status, int count) => '$status ($count)';

  // ==================== INVENTARIO (MATERIALES) ====================
  static const inventoryTitle = 'Gestor de Inventario';
  static const addMaterial = 'Añadir Material';
  static const editMaterial = 'Editar Material';
  static const inventoryEmpty =
      'No hay materiales en el inventario. Añade tu primera bobina o tanque de resina.';
  static const colType = 'Tipo';
  static const colColor = 'Color';
  static const colCostPerKg = 'Coste/Kg';
  static const colStockLeft = 'Stock Restante';
  static const colActions = 'Acciones';
  static const materialResinShort = 'Resina';
  static const materialFilamentShort = 'Filamento';
  static const materialTypeLabel = 'Tipo de Material';
  static const materialTypeFilament = 'Filamento (Bobina)';
  static const materialTypeResin = 'Resina (Tanque/Bote)';
  static const materialNameLabel = 'Nombre/Marca';
  static const materialColorLabel = 'Color';
  static const materialCostPerKg = 'Coste por Kg (€)';
  static const materialStockLabel = 'Stock (gramos/ml)';
  static String grams(double grams) => '${grams.toStringAsFixed(0)} g';

  // ==================== PIEZAS (EXTRAS) ====================
  static const extrasTitle = 'Piezas';
  static const addPieces = 'Añadir Piezas';
  static const addExtra = 'Añadir Extra';
  static const editExtra = 'Editar Extra';
  static const unitsPerPackage = 'Unidades por paquete';
  static const totalPricePackage = 'Precio total del paquete (€)';
  static const addStock = 'Sumar unidades';
  static const addUnits = 'Unidades a añadir';
  static const totalPriceOfUnits = 'Precio total de estas unidades (€)';
  static String units(int count) => '$count uds';
  static String addUnitsTo(String name) => '$addUnits a "$name"';
  static String currentStock(int stock, String unitPrice) =>
      'Actualmente: $stock unidades · $unitPrice c/u';
  static String newUnitPriceEstimate(String price) =>
      'Nuevo precio unitario estimado: $price';

  // ==================== PEDIDOS: LISTADO ====================
  static const ordersTitle = 'Registro de Pedidos';
  static const searchProject = 'Buscar proyecto...';
  static const filterByStatus = 'Filtrar por Estado';
  static const clearFilters = 'Limpiar Filtros';
  static const noOrdersForFilters =
      'No se encontraron pedidos con estos filtros.';
  static const colIdDate = 'ID / Fecha';
  static const colProject = 'Proyecto';
  static const colStatus = 'Estado';
  static const colFinances = 'Finanzas';
  static const colDetails = 'Detalles';
  static String orderTotal(String amount) => 'Total: $amount';
  static String orderPaid(String amount) => 'Pagado: $amount';
  static String orderPending(String amount) => 'Falta: $amount';
  static const painted = 'Pintado';
  static String platesCount(int count) =>
      '$count Placa${count != 1 ? 's' : ''}';
  static String wastePercent(double percent) =>
      '+${percent.toStringAsFixed(0)}% Merma';
  static const changeStatusTooltip = 'Cambiar estado rápidamente';
  static const completeTooltip = 'Marcar como Completado (Resta Stock)';
  static const completeTitle = '¿Completar Pedido?';
  static const completeMessage =
      'Al completar este pedido, se restará el material de tu inventario. ¿La impresión ha sido exitosa?';
  static const completeConfirm = 'Sí, completar';
  static const orderCompleted = 'Pedido completado y stock actualizado';
  static const wasteTooltip = 'Registrar Impresión Fallida';
  static const deleteOrderTitle = '¿Eliminar Pedido?';
  static const deleteOrderMessage =
      'Esta acción no se puede deshacer. Los datos financieros desaparecerán.';
  static const wasteRegistered = 'Merma registrada y stock actualizado';

  // ==================== PEDIDOS: FORMULARIO ====================
  static const editOrder = 'Editar Pedido';
  static const saveOrder = 'Guardar Pedido';
  static const locked = 'BLOQUEADO';
  static const clientOptional = 'Cliente (Opcional)';
  static const unassigned = 'Sin asignar';
  static const createNewClient = 'Crear nuevo cliente';
  static const projectName = 'Nombre del Proyecto';
  static const status = 'Estado';
  static const platesConfigTitle = 'Configuración por Placas';
  static const addPlate = 'Añadir Placa';
  static const noPlates = 'No hay placas. Añade una para empezar a calcular.';
  static String defaultPlateName(int number) => 'Placa $number';
  static const plateNameLabel = 'Nombre de la Placa (ej. Base)';
  static const materialLabel = 'Material';
  static const newMaterialTooltip = 'Nuevo material';
  static String materialOption(String name, String color, String costPerKg) =>
      '$name ($color) - $costPerKg/kg';
  static const gramsLabel = 'Gramos (g)';
  static const timeLabel = 'Tiempo';
  static const extrasSectionTitle = 'Extras (llaveros, clickers, etc.)';
  static const noExtrasDefined = 'No hay extras definidos.';
  static const financesTitle = 'Finanzas y Tiempos Extra';
  static const totalPlatesAuto = 'Total Placas (Automático)';
  static const paintServiceTitle = 'Servicio de Pintura';
  static const paintHoursLabel = 'Horas Pintura';
  static const costManufacture = 'Coste Fabricación';
  static const suggestedPrice = 'Precio Sugerido';
  static const finalPriceLabel = 'Precio Final (€)';
  static const paidAdvanceLabel = 'Pagado / Adelanto';

  // ==================== PEDIDOS: MERMA ====================
  static const wasteDialogTitle = 'Registrar Merma';
  static const registerWaste = 'Registrar Pérdida';
  static const orderHasNoPlates = 'Este pedido no tiene placas configuradas.';
  static const whichPlateFailed = '¿Qué placa ha fallado?';
  static const howMuchPrinted = '¿Cuánto se llegó a imprimir?';
  static String plateOption(String name, double grams) => '$name (${grams}g)';
  static String percent(double value) => '${value.toInt()}%';
  static String gramsToDeduct(double grams) =>
      'Se descontarán ${grams.toStringAsFixed(1)}g del inventario';
  static const wasteReasonLabel = 'Motivo del fallo (Opcional)';
  static const wasteReasonHint =
      'Ej: Se soltó de la cama, atasco de boquilla...';
  static String defaultWasteReason(double percent, String plateName) =>
      'Fallo al ${percent.toInt()}% en $plateName';

  // ==================== CLIENTES ====================
  static const clientsTitle = 'Agenda de Clientes';
  static const clientsSubtitle =
      'Gestiona tus contactos y compradores recurrentes';
  static const clientsEmpty = 'Aún no tienes clientes registrados.';
  static const newClient = 'Nuevo Cliente';
  static const editClient = 'Editar Cliente';
  static const optionalFields =
      'Todos los campos son opcionales. Rellena solo lo que sepas.';
  static const clientNameLabel = 'Nombre / Alias';
  static const clientPhoneLabel = 'Teléfono (WhatsApp)';
  static const clientContactLabel = 'Email / Instagram';
  static String clientPhone(String phone) => '📞 $phone';
  static String clientEmail(String email) => '✉️ $email';

  // ==================== ADMINISTRACIÓN (AJUSTES) ====================
  static const settingsTitle = 'Administración';
  static const pricingCalculatorTitle = 'Calculadora de Precios (Constantes)';
  static const pricingCalculatorHint =
      'Estos valores afectarán automáticamente a los nuevos pedidos creados.';
  static const profitMarginLabel = 'Margen de Beneficio (%)';
  static const paintingCostLabel = 'Coste de Pintado (€/hora)';
  static const plateExtraCostLabel = 'Extra por Placa Base (€)';
  static const saveSettings = 'Guardar Configuración';
  static const settingsUpdated = 'Variables actualizadas correctamente';
}
