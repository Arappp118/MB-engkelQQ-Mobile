/// ServiceItem — master item/jasa/sparepart dari backend.
///
/// Berasal dari endpoint GET /api/v1/service-items.
/// Mechanic HANYA boleh melihat daftar ini (viewAny = true untuk semua role).
/// Mechanic TIDAK boleh mengubah harga (ServiceItemPolicy: only admin).
///
/// Response JSON:
/// {
///   "id": 1,
///   "category": "sparepart",
///   "name": "Oli Mesin",
///   "description": "...",
///   "price": 50000.0,
///   "unit": "liter",
///   "stock": 100,
///   "is_sparepart": true,
///   "is_active": true
/// }
class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.name,
    required this.price,
    this.category,
    this.description,
    this.unit,
    this.stock,
    this.isSparepart = false,
    this.isActive = true,
  });

  final int id;
  final String name;

  /// Harga dari database — ini adalah authority.
  /// Flutter tidak boleh mengubah atau mengirimkan harga sendiri.
  final double price;

  final String? category;
  final String? description;
  final String? unit;
  final int? stock;
  final bool isSparepart;
  final bool isActive;

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: _toInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      price: _toDouble(json['price']) ?? 0,
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      unit: json['unit']?.toString(),
      stock: _toInt(json['stock']),
      isSparepart: json['is_sparepart'] == true,
      isActive: json['is_active'] != false,
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
