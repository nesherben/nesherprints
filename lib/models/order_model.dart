class Order {
  final int? id;
  final String name;
  final double price;
  final String date;
  final String status;
  final double grams;
  final int plates;
  final bool isPainted;

  Order({
    this.id,
    required this.name,
    required this.price,
    required this.date,
    required this.status,
    required this.grams,
    required this.plates,
    required this.isPainted,
  });

  // Para cuando conectemos la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'date': date,
      'status': status,
      'grams': grams,
      'plates': plates,
      'is_painted': isPainted ? 1 : 0,
    };
  }
}
