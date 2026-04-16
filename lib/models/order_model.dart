class OrderModel {
  final int? id; // El ID es opcional porque al crear uno nuevo aún no existe
  final String name;
  final double price;
  final String date;
  final String status;
  final double grams;
  final int plates;
  final bool isPainted;

  OrderModel({
    this.id,
    required this.name,
    required this.price,
    required this.date,
    required this.status,
    required this.grams,
    required this.plates,
    required this.isPainted,
  });

  // Convierte el objeto a un Mapa para guardarlo en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'date': date,
      'status': status,
      'grams': grams,
      'plates': plates,
      'is_painted': isPainted
          ? 1
          : 0, // SQLite no tiene booleanos, usamos 0 o 1
    };
  }

  // Crea un objeto a partir de un Mapa (cuando leemos de la base de datos)
  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      date: map['date'],
      status: map['status'],
      grams: map['grams'],
      plates: map['plates'],
      isPainted: map['is_painted'] == 1,
    );
  }
}
