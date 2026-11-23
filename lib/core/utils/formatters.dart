/// Importe en euros con 2 decimales: `€12.50`.
String formatEuro(double value, {int decimals = 2}) =>
    '€${value.toStringAsFixed(decimals)}';

/// Fecha de hoy en formato `YYYY-MM-DD` (formato guardado en `orders.date`).
String todayIsoDate([DateTime? now]) =>
    (now ?? DateTime.now()).toString().split(' ')[0];
