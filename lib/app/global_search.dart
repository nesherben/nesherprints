import 'package:nesherprints/core/utils/text_utils.dart';
import 'package:nesherprints/features/clients/domain/client.dart';
import 'package:nesherprints/features/extras/domain/extra.dart';
import 'package:nesherprints/features/inventory/domain/print_material.dart';
import 'package:nesherprints/features/orders/domain/order.dart';

/// Qué tipo de cosa es un resultado del buscador global.
enum SearchKind { order, client, extra, material }

/// Un resultado del buscador global (Ctrl+K).
class SearchHit {
  const SearchHit({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final SearchKind kind;
  final int id;
  final String title;
  final String subtitle;
}

/// Búsqueda en todos los datos de la app (lógica pura): pedidos, clientes,
/// piezas y materiales. Primero lo que empieza por el texto, luego lo que lo
/// contiene.
class GlobalSearch {
  GlobalSearch._();

  /// Resultados máximos por tipo.
  static const int perKind = 6;

  static List<SearchHit> search(
    String query, {
    required List<OrderSummary> orders,
    required List<Client> clients,
    required List<Extra> extras,
    required List<PrintMaterial> materials,
  }) {
    final q = foldText(query.trim());
    if (q.isEmpty) return const [];

    /// 0 = empieza por el texto, 1 = lo contiene, `null` = no coincide.
    int? score(Iterable<String> fields) {
      int? best;
      for (final f in fields) {
        final t = foldText(f);
        if (t.isEmpty) continue;
        final s = t.startsWith(q) ? 0 : (t.contains(q) ? 1 : null);
        if (s != null && (best == null || s < best)) best = s;
      }
      return best;
    }

    List<SearchHit> pick<T>(
      Iterable<T> items,
      Iterable<String> Function(T) fields,
      SearchHit Function(T) hit,
    ) {
      final scored = <(int, SearchHit)>[];
      for (final item in items) {
        final s = score(fields(item));
        if (s != null) scored.add((s, hit(item)));
      }
      scored.sort((a, b) => a.$1.compareTo(b.$1));
      return [for (final (_, h) in scored.take(perKind)) h];
    }

    return [
      ...pick<OrderSummary>(
        orders,
        (o) => [
          o.order.name,
          '#${o.id}',
          '${o.id}',
          o.clientName ?? '',
          o.plateNames ?? '',
        ],
        (o) => SearchHit(
          kind: SearchKind.order,
          id: o.id,
          title: o.order.name,
          subtitle:
              '#${o.id} · ${o.order.status.label}'
              '${o.clientName == null ? '' : ' · ${o.clientName}'}',
        ),
      ),
      ...pick<Client>(
        clients,
        (c) => [c.name, c.phone, c.email],
        (c) => SearchHit(
          kind: SearchKind.client,
          id: c.id!,
          title: c.name,
          subtitle: [c.phone, c.email].where((s) => s.isNotEmpty).join(' · '),
        ),
      ),
      ...pick<Extra>(
        extras,
        (e) => [e.name],
        (e) => SearchHit(
          kind: SearchKind.extra,
          id: e.id!,
          title: e.name,
          subtitle: '${e.stock} uds',
        ),
      ),
      ...pick<PrintMaterial>(
        materials,
        (m) => [m.name, m.color],
        (m) => SearchHit(
          kind: SearchKind.material,
          id: m.id!,
          title: m.color.isEmpty ? m.name : '${m.name} · ${m.color}',
          subtitle: m.kind == MaterialKind.resin ? 'Resina' : 'Filamento',
        ),
      ),
    ];
  }
}
