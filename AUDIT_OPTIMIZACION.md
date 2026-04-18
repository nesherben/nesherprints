# 📊 AUDITORÍA DE NAVEGABILIDAD Y OPTIMIZACIÓN

## 🔴 PROBLEMAS IDENTIFICADOS

### 1. **REPOSITORIOS SIN SINGLETON** (CRÍTICO)
- ❌ 14+ instancias de repositorios creadas independientemente
- ❌ `OrderRepository()` se crea en: main_layout, dashboard, order_form_dialog, waste_dialog, status_badge, orders_view
- ❌ Cada pantalla = nueva instancia = posible inconsistencia de datos

**Ubicaciones problemáticas:**
```
main_layout.dart:23-24        (OrderRepo, MaterialRepo)
dashboard_view.dart:17-18     (OrderRepo, MaterialRepo)
order_form_dialog.dart:27-30  (4 repos)
waste_dialog.dart:16          (OrderRepo)
orders_view.dart:59           (ClientRepo - inline)
status_badge.dart:47          (OrderRepo - inline)
```

### 2. **RUTAS Y NAVEGACIÓN SIN CENTRALIZAR**
- ❌ No hay archivo central con nombres de rutas
- ❌ Los nombres de pantallas están hardcodeados en NavigationRail
- ❌ No hay forma rápida de saber qué pantallas existen

### 3. **CONSTANTES MÁGICAS DISPERSAS**
- ❌ 'resin' / 'filament' repetidos en inventory_view, material_dialog, forms
- ❌ Strings de estado ('Completed', 'In Progress') por todo el código
- ❌ Valores por defecto (200g stock warning, 45.0 margin) hardcodeados

### 4. **IMPORTS DESORGANIZADOS - DIFÍCIL BUSCAR COSAS**
- ❌ Sin patrón de imports: relativos vs absolutos mezclados
- ❌ Sin export files que centralicen lo público
- ❌ Buscar una clase = buscar en 20 archivos

### 5. **DUPLICACIÓN DE LÓGICA**
- ❌ `_loadXxx()` repetido en 5+ pantallas
- ❌ Patrón setState + rebuild en cada View
- ❌ Callbacks de actualización reinventan la rueda

---

## 🟢 SOLUCIONES PROPUESTAS (PRAGMÁTICAS)

### FASE 1: Singleton de Repositorios (FÁCIL - 30 min)
✅ Crear `lib/data/service_locator.dart`
✅ Una instancia global de cada repo
✅ Acceso desde cualquier lado: `ServiceLocator.orderRepo.getAllOrders()`

### FASE 2: Centralizar Constantes (FÁCIL - 20 min)
✅ Crear `lib/core/constants.dart`
✅ Agrupar: material types, order statuses, validation rules
✅ Ejemplos:
   - `const MATERIAL_TYPE_RESIN = 'resin'`
   - `const ORDER_STATUS_COMPLETED = 'Completed'`
   - `const LOW_STOCK_WARNING_G = 200.0`

### FASE 3: Rutas y Pantallas (FÁCIL - 25 min)
✅ Crear `lib/core/routes.dart`
✅ Enum de pantallas + metadata
✅ Centralizar la lista de screens y navigation

### FASE 4: Exports / Barrels (FÁCIL - 15 min)
✅ Crear archivos `export.dart` en cada carpeta
✅ Simplificar imports
✅ Ejemplos:
   - `lib/data/export.dart` → importa todos los repos
   - `lib/presentation/screens/export.dart` → importa todas las views

---

## 📋 VERIFICACIÓN ANTES DE IMPLEMENTAR

**Preguntas clave:**
1. ¿Quieres empezar por Singleton (afecta todo el proyecto)?
2. ¿O prefieres Constantes primero (menos riesgo, máximo impacto)?
3. ¿Cuál te interesa más para la navegabilidad?

---

## 💡 BENEFICIOS ESPERADOS

| Problema | Solución | Beneficio |
|----------|----------|-----------|
| Múltiples instancias | Singleton | Datos consistentes + memoria optimizada |
| Constantes hardcodeadas | constants.dart | Buscar valor = 1 lugar |
| Rutas desorganizadas | routes.dart | Find pantalla = IDE autocomplete |
| Imports caóticos | barrels | 1 import clara = menos líneas |
| Difícil buscar clase X | barrels + índice | Grep intelligente del proyecto |

