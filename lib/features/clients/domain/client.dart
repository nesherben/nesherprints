import 'package:nesherprints/core/database/db_schema.dart';

/// Cliente de la agenda.
class Client {
  const Client({
    this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.notes = '',
  });

  final int? id;
  final String name;
  final String phone;

  /// Email o usuario de Instagram (campo libre).
  final String email;
  final String notes;

  /// Iniciales para el avatar (hasta dos letras; `?` si no hay nombre).
  String get initials {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words
        .take(2)
        .map((w) => String.fromCharCode(w.runes.first));
    final text = letters.join().toUpperCase();
    return text.isEmpty ? '?' : text;
  }

  /// Construye un cliente desde el formulario aplicando las reglas de la
  /// agenda. Devuelve `null` si todos los campos están vacíos (no se guarda).
  /// Si falta el nombre, se usa el teléfono o, si no, el email.
  static Client? fromForm({
    int? id,
    required String name,
    required String phone,
    required String email,
    String notes = '',
  }) {
    final n = name.trim(), p = phone.trim(), e = email.trim();
    if (n.isEmpty && p.isEmpty && e.isEmpty) return null;
    return Client(
      id: id,
      name: n.isNotEmpty ? n : (p.isNotEmpty ? p : e),
      phone: p,
      email: e,
      notes: notes,
    );
  }

  factory Client.fromMap(Map<String, Object?> map) => Client(
    id: map[ClientsTable.id] as int?,
    name: map[ClientsTable.clientName] as String? ?? '',
    phone: map[ClientsTable.phone] as String? ?? '',
    email: map[ClientsTable.email] as String? ?? '',
    notes: map[ClientsTable.notes] as String? ?? '',
  );

  Map<String, Object?> toMap() => {
    if (id != null) ClientsTable.id: id,
    ClientsTable.clientName: name,
    ClientsTable.phone: phone,
    ClientsTable.email: email,
    ClientsTable.notes: notes,
  };
}
