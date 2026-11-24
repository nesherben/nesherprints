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
  static const newOrder = 'Nuevo pedido';

  static const brandName = 'NesherPrints';
  static const loadErrorTitle = 'No se pudieron cargar los datos';
  static const retry = 'Reintentar';

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
  static const dashboardTitle = 'Panel';
  static const monthlyChartTitle = 'Facturación y beneficio por mes';
  static String chartTooltipGross(String month, String amount) =>
      '$month\nFacturado $amount';
  static String chartTooltipProfit(String amount, String margin) =>
      'Beneficio $amount\nMargen $margin';
  static const ordersWord = 'pedidos';
  static const monthlyDetailTitle = 'Detalle mensual';
  static const colMonth = 'Mes';
  static const colOrders = 'Pedidos';
  static const colGross = 'Facturado';
  static const colProfit = 'Beneficio';
  static const colMargin = 'Margen';
  static const pendingListTitle = 'Pendientes de cobro';
  static const allCollected = 'Todo cobrado';
  static String orderNumber(int id) => 'Pedido #$id';
  static String pendingAge(int id, int days) => days == 0
      ? 'Pedido #$id · de hoy'
      : days == 1
      ? 'Pedido #$id · hace 1 día'
      : 'Pedido #$id · hace $days días';
  static String completedOrdersCount(int n) =>
      n == 1 ? '1 pedido completado' : '$n pedidos completados';
  static String marginOnRevenue(String pct) =>
      'Margen del $pct sobre lo facturado';
  static String pendingOrdersCount(int n) => n == 0
      ? 'Nada pendiente'
      : (n == 1 ? '1 pedido por cobrar' : '$n pedidos por cobrar');
  static const kpiGoal = 'Objetivo de beneficio';
  static String goalOf(String current, String goal) => '$current de $goal';
  static String wasteNote(int records, double grams, String cost) =>
      'Mermas registradas: $records · ${grams.toStringAsFixed(0)} g · $cost de material.';
  static const billingHistoryTitle = 'Histórico de Facturación';
  static const dashboardSubtitle =
      'Cómo va tu negocio: facturación, beneficio, objetivo y cobros.';
  static const kpiGrossRevenue = 'Facturado';
  static const kpiNetProfit = 'Beneficio real';
  static const kpiPendingCollection = 'Pendiente de Cobro';
  static const grossLabel = 'Facturado';
  static const netLabel = 'Beneficio';
  static const distributionTitle = 'Pedidos por estado';
  static const completeFirstOrderHint =
      'Completa tu primer pedido para ver el gráfico.';
  static String statusLegend(String status, int count) => '$status ($count)';

  // ==================== INVENTARIO (MATERIALES) ====================
  static const inventoryTitle = 'Inventario';
  static const addMaterial = 'Nuevo material';
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
  static const addPieces = 'Nueva pieza';
  static String unitPricePreview(String amount) => '≈ $amount por unidad';
  static const filterSoldOutExtras = 'Agotadas';
  static const addExtra = 'Añadir Pieza';
  static const editExtra = 'Editar Pieza';
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
  static const ordersTitle = 'Pedidos';
  static const searchProject = 'Buscar proyecto...';
  static const filterByStatus = 'Filtrar por Estado';
  static const clearFilters = 'Limpiar Filtros';
  static const noOrdersForFilters =
      'No se encontraron pedidos con estos filtros.';
  static const colIdDate = 'ID / Fecha';
  static const colId = 'ID';
  static const noDate = 'Sin fecha';
  static String monthGroupMeta(int count, String billed) =>
      '${ordersCount(count)} · $billed facturado';
  static const colDate = 'Fecha';
  static const colClient = 'Cliente';
  static const colPrice = 'Precio';
  static const colCollection = 'Cobro';
  static String pendingShort(String amount) => 'Falta $amount';
  static const colProject = 'Proyecto';
  static const colStatus = 'Estado';
  static const colFinances = 'Finanzas';
  static const colDetails = 'Detalles';
  static String orderTotal(String amount) => 'Total: $amount';
  static String orderPaid(String amount) => 'Pagado: $amount';
  static String orderPending(String amount) => 'Falta: $amount';
  static const painted = 'Pintado';
  static String profitOf(String amount) => 'Beneficio $amount';
  static String platesCount(int count) =>
      '$count Placa${count != 1 ? 's' : ''}';
  static String wastePercent(double percent) =>
      '+${percent.toStringAsFixed(0)}% Merma';
  static const changeStatusTooltip = 'Cambiar estado rápidamente';
  static const completeTooltip = 'Completar pedido (descuenta el material)';
  static const completeTitle = 'Completar pedido';
  static const completeConfirm = 'Sí, completar';
  static const orderCompleted = 'Pedido completado y stock actualizado';
  static const wasteTooltip = 'Registrar Impresión Fallida';
  static const deleteOrderTitle = 'Eliminar pedido';
  static const wasteRegistered = 'Merma registrada y stock actualizado';

  // ==================== PEDIDOS: FORMULARIO ====================
  static const editOrder = 'Editar pedido';
  static const saveOrder = 'Guardar pedido';
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
  static const plateNameLabel = 'Nombre';
  static const materialLabel = 'Material';
  static const newMaterialTooltip = 'Nuevo material';
  static String materialOption(String name, String color, String costPerKg) =>
      '$name ($color) - $costPerKg/kg';
  static const gramsLabel = 'Gramos';
  static const timeLabel = 'Tiempo';
  static const extrasSectionTitle = 'Extras (llaveros, clickers, etc.)';
  static const noExtrasDefined = 'No hay extras definidos.';
  static const financesTitle = 'Finanzas y Tiempos Extra';
  static const totalPlatesAuto = 'Total Placas (Automático)';
  static const paintServiceTitle = 'Servicio de Pintura';
  static const attemptsLabel = 'Intentos (1 = a la primera)';
  static const costManufacture = 'Coste Fabricación';
  static const suggestedPrice = 'Precio recomendado';
  static const finalPriceLabel = 'Precio Final (€)';
  static const paidAdvanceLabel = 'Pagado / Adelanto';

  // ==================== PEDIDOS: LISTADO (rediseño) ====================
  static String ordersCount(int n) => n == 1 ? '1 pedido' : '$n pedidos';
  static const searchOrdersHint =
      'Buscar por proyecto, cliente, nº de pedido o placa…  (Ctrl+F)';
  static const clearSearch = 'Borrar búsqueda';
  static const filterAll = 'Todos';
  static const filterReceivable = 'Por cobrar';
  static const sortBy = 'Ordenar por';
  static const sortPending = 'Pendiente de cobro';
  static String showingCount(int shown, int total) =>
      'Mostrando $shown de $total pedidos';
  static const emptyOrdersTitle = 'Aún no hay pedidos';
  static const emptyOrdersMessage =
      'Crea el primero para calcular su precio y llevar el stock al día.';
  static const createFirstOrder = 'Crear el primer pedido';
  static const emptyMatchesTitle = 'Ningún pedido coincide';
  static const emptyMatchesMessage =
      'Prueba con otra búsqueda o quita los filtros.';
  static const colDetailsUpper = 'DETALLES';
  static const collected = 'Cobrado';
  static String paidOfPending(String paid, String pending) =>
      'Pagado $paid · Falta $pending';
  static const viewAction = 'Ver pedido';
  static const editAction = 'Editar pedido';
  static const moreActions = 'Más acciones';
  static const wasteAction = 'Registrar merma';
  static const duplicateAction = 'Duplicar';
  static const deleteAction = 'Eliminar';
  static String completeMessage(double grams) =>
      'El pedido pasará a «Completado» y «Cobrado» y se descontarán '
      'unos ${grams.toStringAsFixed(0)} g de material del inventario. '
      'No se puede deshacer.';
  static String stockShortageLine(String name, double need, double have) =>
      '• $name: hacen falta ${need.toStringAsFixed(0)} g y hay '
      '${(have < 0 ? 0 : have).toStringAsFixed(0)} g.';
  static const stockShortageIntro =
      '\n\nOjo: no hay stock suficiente y el inventario quedará en negativo:\n';
  static String deleteOrderMessage(String name) =>
      'Se eliminará «$name» con sus placas y mermas. Las piezas extra '
      'vuelven al stock; el material ya gastado no se repone.';
  static const orderSaved = 'Pedido guardado';
  static const orderDeleted = 'Pedido eliminado';
  static String statusChanged(String label) => 'Estado cambiado a «$label»';
  static const wasteDialogSubtitle = 'Resta del inventario el material perdido';
  static const nothingToDeduct =
      'Mueve el deslizador para indicar cuánto se perdió';

  // ==================== PEDIDOS: FORMULARIO (rediseño) ====================
  static const platesSectionHint =
      'Cada placa lleva su material, sus gramos y su tiempo de impresión.';
  static const duplicatePlate = 'Duplicar placa';
  static const removePlate = 'Quitar placa';
  static String materialName(String name, String color) =>
      color.isEmpty ? name : '$name · $color';
  static String notEnoughStock(double stock) =>
      'Solo quedan ${stock.toStringAsFixed(0)} g de este material';
  static String plateMaterialCost(String cost, double stock) =>
      '$cost de material · quedan ${stock.toStringAsFixed(0)} g';
  static const extrasSectionHint =
      'Se descuentan del stock al guardar el pedido.';
  static String extrasTotal(String amount) => 'Piezas: $amount';
  static String extraNotEnough(int stock) => 'Solo quedan $stock unidades';
  static String extraPriceStock(String price, int stock) =>
      '$price/ud · quedan $stock';
  static const removeOne = 'Quitar una';
  static const sectionCost = 'Coste';
  static const sectionPrice = 'Precio';
  static const sectionCollection = 'Cobro';
  static String realProfit(String amount) => 'Beneficio real $amount';
  static const pickExtra = 'Añadir pieza';
  static const removeExtraLine = 'Quitar pieza';
  static const noExtrasSelected = 'Sin piezas extra en este pedido.';
  static const addOne = 'Añadir una';
  static const summaryTitle = 'RESUMEN';
  static String summaryMeta(int plates, String time, double grams) =>
      '${plates == 1 ? '1 placa' : '$plates placas'} · $time · '
      '${grams.toStringAsFixed(0)} g';
  static const lineMaterial = 'Material';
  static const linePaint = 'Pintura';
  static const lineExtras = 'Piezas';
  static String attemptsNote(String attempts) =>
      'Intentos ×$attempts aplicados a material y luz';
  static const costReal = 'Coste real';
  static const quickPaidNone = '0 €';
  static const quickPaidHalf = '50 %';
  static const quickPaidAll = 'Todo';
  static String healthGood(String benefit, double pct) =>
      'Beneficio $benefit (+${pct.toStringAsFixed(0)} % sobre el coste)';
  static String healthLow(String diff, String benefit) =>
      'Por debajo del recomendado ($diff menos). Beneficio $benefit';
  static String healthLoss(String loss) =>
      'Pierdes $loss: el precio no cubre el coste';
  static const healthHint = 'Escribe el precio final para ver tu margen';
  static const fullyPaid = 'Cobrado por completo';
  static String overpaid(String amount) => 'Cobras $amount más que el precio';
  static const notesLabel = 'Notas';
  static const discardTitle = '¿Descartar los cambios?';
  static const discardMessage =
      'Has modificado el pedido y todavía no lo has guardado.';
  static const discard = 'Descartar';
  static const keepEditing = 'Seguir editando';
  static String pendingToCollect(String amount) => 'Falta por cobrar: $amount';
  static const copySuffix = ' (copia)';
  static const viewOrder = 'Pedido';
  static const duplicateOrderTitle = 'Duplicar pedido';
  static String orderSubtitle(int id, String date) =>
      date.isEmpty ? 'Pedido #$id' : 'Pedido #$id · $date';
  static String errorsMore(String first, int more) => '$first (y $more más)';
  static const saving = 'Guardando…';
  static const close = 'Cerrar';
  static const orderDataTitle = 'Datos del pedido';
  static const productionTitle = 'Producción';
  static const lockedBanner =
      'Pedido completado o enviado: solo lectura. El material ya se '
      'descontó del inventario.';
  static const attemptsHelp =
      'Reimpresiones por fallos: sube el coste, no el precio recomendado.';

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
  static const clientsTitle = 'Clientes';
  static const clientsSubtitle =
      'Gestiona tus contactos y compradores recurrentes';
  static const clientsEmpty = 'Aún no tienes clientes registrados.';
  static const newClient = 'Nuevo cliente';
  static const clientsSummaryCount = 'Clientes';
  static const clientsSummaryBilled = 'Facturado';
  static const clientsSummaryOwed = 'Por cobrar';
  static const filterWithOrders = 'Con pedidos';
  static const filterOwes = 'Con deuda';
  static const editClient = 'Editar Cliente';
  static const optionalFields =
      'Todos los campos son opcionales. Rellena solo lo que sepas.';
  static const clientNameLabel = 'Nombre / Alias';
  static const clientPhoneLabel = 'Teléfono (WhatsApp)';
  static const clientContactLabel = 'Email / Instagram';
  static String clientPhone(String phone) => '📞 $phone';
  static String clientEmail(String email) => '✉️ $email';

  // ==================== INVENTARIO / PIEZAS / CLIENTES (REDISEÑO) ====================
  static const listClearSearch = 'Borrar búsqueda';
  static const listNoResultsTitle = 'Sin resultados';
  static const listNoResultsMessage =
      'Ningún elemento coincide con la búsqueda.';
  static const copied = 'Copiado';

  // Inventario
  static const inventorySubtitle =
      'Tus colores de filamento y el tanque de resina';
  static const resinSection = 'Resina';
  static const filamentSection = 'Estantería de filamento';
  static String filamentColorsMeta(int n) => n == 1 ? '1 color' : '$n colores';
  static String filamentGroupSubtitle(int n) =>
      n == 1 ? '1 color' : '$n colores';
  static const addResin = 'Añadir resina';
  static const colorsButton = 'Colores';
  static const libraryManageTitle = 'Biblioteca de colores';
  static const libraryManageSubtitle =
      'Los colores que se sugieren al dar de alta un filamento. Puedes cambiar o borrar cualquiera.';
  static const libraryEmpty =
      'La biblioteca está vacía. Añade colores o restaura los básicos.';
  static const restoreBasics = 'Restaurar básicos';
  static const newColor = 'Nuevo color';
  static const editColor = 'Editar color';
  static const colorNameLabel = 'Nombre del color';
  static String deleteColorTooltip(String name) => 'Quitar "$name"';
  static const resinStatAmount = 'En el tanque';
  static const resinStatValue = 'Valor';
  static const resinStatValueHint = 'de lo que hay ahora';
  static const perKg = 'por kilo (medio)';
  static const shelfEmptyTitle = 'La estantería está vacía';
  static const shelfEmptyMessage =
      'Añade tus filamentos de uno en uno o pega la lista de colores de una marca.';
  static const pickColorTitle = 'Elegir color';
  static const hexLabel = 'Código hexadecimal';
  static const libraryTitle = 'Tu biblioteca de colores';
  static const pickColorTooltip = 'Elegir color (RGB)';
  static const colorFromLibrary = 'En tu biblioteca';
  static const resinTankTitle = 'Tanque de resina';
  static const resinTankSubtitle =
      'Total acumulado, con el precio medio de todo lo que has echado';
  static const defaultResinName = 'Resina';
  static String shelfBrandMeta(int n) => n == 1 ? '1 bobina' : '$n bobinas';
  static const addSeveral = 'Añadir varios';
  static const bulkTitle = 'Añadir varios filamentos';
  static const bulkSubtitle =
      'Marca y precio una vez; luego los colores, uno tras otro';
  static const bulkDefaultPrice = 'Precio por defecto';
  static const bulkColorsLabel = 'Colores';
  static const bulkColorsHint =
      'Escribe un color y pulsa Enter (o pega una lista)';
  static const bulkLibraryHint = 'O toca los de tu biblioteca';
  static String bulkRemoveTooltip(String color) => 'Quitar "$color"';
  static const bulkEmptyHint =
      'Un color por línea. Con «Color: precio» se usa un precio propio.';
  static String bulkReady(int n) =>
      n == 1 ? '1 color listo' : '$n colores listos';
  static String bulkCreate(int n) => n == 0 ? 'Crear' : 'Crear $n';
  static String bulkAdded(int n) =>
      n == 1 ? '1 filamento añadido' : '$n filamentos añadidos';
  static String addResinTo(String name) => 'Añadir resina a "$name"';
  static const resinGramsLabel = 'Cantidad a añadir';
  static const resinBatchPriceLabel = 'Precio de esta remesa';
  static String resinNow(String stock, String price) =>
      'Ahora: $stock a $price/kg';
  static const resinPriceNow = 'Precio medio actual';
  static const resinPriceNew = 'Nuevo precio medio';
  static String resinAfter(String stock) => 'En el tanque quedarán $stock';
  static const resinApplyHint =
      'Indica los gramos para ver el nuevo precio medio';
  static String resinValue(String value) => '$value en el tanque';
  static const resinGramsInvalid = 'Indica los gramos (más de 0)';
  static const resinCurrentStock = 'Gramos en el tanque (ahora)';
  static const inventorySearchHint = 'Buscar por nombre, color o tipo...';
  static const inventoryEmptyTitle = 'Aún no hay materiales';
  static const inventorySummaryMaterials = 'Materiales';
  static const inventorySummaryStock = 'Stock total';
  static const inventorySummaryLow = 'Con stock bajo';
  static const inventorySummaryOut = 'Agotados';
  static const outOfStock = 'Agotado';
  static const filterInStock = 'Con stock';
  static String materialGroupSubtitle(int variants, String stock) =>
      '$variants variantes · $stock';
  static String kilos(double grams) =>
      '${(grams / 1000).toStringAsFixed(2)} kg';
  static String pricePerKg(String price) => '$price/kg';
  static const lowStock = 'Stock bajo';
  static const materialNameRequired = 'Indica el nombre o la marca';
  static const materialCostInvalid = 'Indica un coste válido (0 o más)';
  static const materialStockInvalid = 'Indica un stock válido (0 o más)';
  static String materialInUse(String name, int plates) =>
      'No se puede eliminar "$name": lo usan $plates placas de pedidos.';

  // Piezas
  static const extrasSubtitle = 'Llaveros, clickers y otras piezas con stock';
  static const extrasSearchHint = 'Buscar pieza...';
  static const extrasEmptyTitle = 'Aún no hay piezas';
  static const extrasEmptyMessage =
      'Añade tu primer paquete de piezas para usarlas en los pedidos.';
  static const extrasSummaryCount = 'Piezas';
  static const extrasSummaryValue = 'Valor del stock';
  static const extrasSummarySoldOut = 'Agotadas';
  static const extraSoldOut = 'Agotado';
  static const extraNegativeStock = 'Stock negativo';
  static const extraFewUnits = 'Pocas unidades';
  static String perUnit(String price) => '$price c/u';
  static const extraNameRequired = 'Indica el nombre de la pieza';
  static const extraUnitsInvalid = 'Indica unidades válidas (0 o más)';
  static const extraPriceInvalid = 'Indica un precio válido (0 o más)';
  static const extraEditHint =
      'El stock no cambia al editar: usa «Sumar unidades» para añadir.';
  static const unitPriceLabel = 'Precio por unidad (€)';
  static const deleteClient = 'Eliminar cliente';
  static String deleteClientMessage(String name, int orders) => orders == 0
      ? '¿Eliminar a «$name»?'
      : '¿Eliminar a «$name»? Sus $orders pedidos se conservan, sin cliente.';
  static const stockUnitPriceNow = 'Precio unitario actual';
  static const stockUnitPriceNew = 'Nuevo precio unitario';
  static const stockApplyHint =
      'Indica las unidades (más de 0) y el precio total para continuar.';
  static String stockAfter(int units) => 'Stock resultante: $units uds';

  // Clientes
  static const clientsSearchHint = 'Buscar por nombre, teléfono o email...';
  static const clientsEmptyMessage =
      'Añade a tus clientes para asignarles pedidos y ver cuánto te deben.';
  static const copyPhone = 'Copiar teléfono';
  static const copyEmail = 'Copiar email';
  static String clientOrders(int count) =>
      count == 1 ? '1 pedido' : '$count pedidos';
  static const noPhone = 'Sin teléfono';
  static const noEmail = 'Sin email';
  static const clientBilled = 'Facturado';
  static const clientPending = 'Por cobrar';
  static const clientUpToDate = 'Al día';

  // ==================== MODELO DE PRECIOS SIMPLE ====================
  static const lineMachine = 'Máquina';
  static const linePlates = 'Placas';
  static const minimumNote = 'Se aplica el precio mínimo';
  static const paintServiceHint =
      'Se suma un importe según el detalle de la figura';
  static String paintSurchargeNote(String amount) =>
      'Incluye +$amount de pintura';
  static const settingsGroupProduction = 'Producción';
  static const settingsGroupProductionHint =
      'Máquina y preparación de cada placa.';
  static const profitMarginHint =
      'Se suma al coste. Con 150 %, un coste de 10 € da un precio '
      'recomendado de 25 €.';
  static const minimumPriceLabel = 'Precio mínimo';
  static const minimumPriceHint =
      'El precio recomendado nunca baja de esto (piezas muy pequeñas).';
  static const kwhPriceLabel = 'Precio de la electricidad';
  static const kwhPriceHint =
      'Lo que pagas por kWh. La impresora consume unos 0,25 kW de media.';
  static const machineCostLabel = 'Coste de la máquina';
  static const machineCostHint =
      'Desgaste y amortización aproximados por hora de impresión, sin '
      'contar la luz.';
  static const plateCostLabel = 'Coste por placa';
  static const plateCostHint =
      'Preparar, laminar y retirar cada placa. Se cobra por cada placa.';
  static const unitEuroPerHour = '€/h';
  static const paintSimpleLabel = 'Pintura simple';
  static const paintSimpleHint =
      'Figura lisa o con pocos detalles. Se suma al precio de la pieza.';
  static const paintNormalLabel = 'Pintura normal';
  static const paintNormalHint = 'Figura con detalle medio.';
  static const paintDetailedLabel = 'Pintura detallada';
  static const paintDetailedHint =
      'Figura con muchos detalles o zonas pequeñas.';
  static const paintDetailLabel = 'Detalle de la figura';
  static const paintDetailSimple = 'Simple';
  static const paintDetailNormal = 'Normal';
  static const paintDetailDetailed = 'Detallada';
  static const unitEuroPerKwh = '€/kWh';
  static const settingsExampleHint =
      '1 placa de 100 g a 20 €/kg, 8 h de impresión, sin pintura ni piezas.';

  // ==================== ADMINISTRACIÓN (AJUSTES) ====================
  static const settingsTitle = 'Administración';
  static const settingsSubtitle =
      'Constantes de la calculadora de precios. Afectan a los pedidos nuevos '
      'y a los que se recalculen.';
  static const settingsUnsaved = 'Cambios sin guardar';
  static const settingsSaved = 'Todo guardado';
  static const saveSettings = 'Guardar';
  static const settingsUpdated = 'Ajustes guardados correctamente';
  static const settingsRestoreAll = 'Restaurar valores por defecto';
  static const settingsRestoreAllTitle = 'Restaurar valores por defecto';
  static const settingsRestoreAllMessage =
      'Todos los campos volverán a sus valores por defecto. Los cambios no '
      'se guardan hasta que pulses Guardar.';
  static const settingsRestoreAllConfirm = 'Restaurar';
  static const settingsRestoreOne = 'Restaurar este valor';
  static String settingsDefaultValue(String value) => 'Por defecto: $value';
  static const settingsErrorRequired = 'Obligatorio';
  static const settingsErrorInvalid = 'Número no válido';
  static const settingsErrorNegative = 'Debe ser 0 o más';
  static String settingsErrorTooBig(double max) =>
      'Máximo ${max.toStringAsFixed(0)}';

  static const settingsGroupPrice = 'Precio';
  static const settingsGroupPriceHint = 'Cuánto ganas sobre el coste.';
  static const settingsGroupPaint = 'Pintura';
  static const settingsGroupPaintHint =
      'Lo que se suma al precio de la pieza según el detalle de la figura.';
  static const settingsGroupGoals = 'Objetivos';
  static const settingsGroupGoalsHint = 'Meta que se muestra en el panel.';

  static const profitMarginLabel = 'Margen de beneficio';
  static const profitGoalLabel = 'Objetivo de beneficio';
  static const profitGoalHint =
      'Beneficio acumulado al que aspiras; el panel mide tu avance.';

  static const unitPercent = '%';
  static const unitEuro = '€';

  static const settingsExampleTitle = 'Ejemplo en vivo';
  static const settingsExampleCost = 'Coste';
  static const settingsExamplePrice = 'Precio recomendado';
  static const settingsExampleInvalid =
      'Corrige los campos con error para ver el ejemplo.';
}
