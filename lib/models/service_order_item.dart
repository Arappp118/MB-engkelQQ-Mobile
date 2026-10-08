/// ServiceOrderItem — item yang sudah terlampir ke service order.
///
/// Struktur ini berasal dari ServiceOrderResource.items:
///
/// {
///   "name": "Oli Mesin",
///   "price": 50000.0,
///   "quantity": 2,
///   "subtotal": 100000.0
/// }
///
/// Backend selalu mengambil harga dari database (snapshot)
/// sehingga Flutter tidak perlu dan tidak boleh mengirimkan
/// harga sebagai sumber kebenaran transaksi.
class ServiceOrderItem {
  const ServiceOrderItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  /// Nama item pada saat transaksi.
  final String name;

  /// Harga per unit saat transaksi.
  ///
  /// Nilai ini merupakan snapshot dari backend.
  final double price;

  /// Jumlah item.
  final int quantity;

  /// Subtotal item.
  ///
  /// Nilai dihitung oleh backend.
  final double subtotal;

  // ============================================================
  // FROM JSON
  // ============================================================

  factory ServiceOrderItem.fromJson(Map<String, dynamic> json) {
    return ServiceOrderItem(
      name: json['name']?.toString() ?? '',
      price: _toDouble(json['price']) ?? 0,
      quantity: _toInt(json['quantity']) ?? 0,
      subtotal: _toDouble(json['subtotal']) ?? 0,
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '');
  }

  static double? _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '');
  }
}
