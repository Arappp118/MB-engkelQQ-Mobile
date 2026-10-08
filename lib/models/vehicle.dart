class Vehicle {
  const Vehicle({
    required this.id,
    required this.userId,
    required this.nomorPolisi,
    required this.merk,
    required this.model,
    this.tahun,
    this.tipeMesin,
    this.transmisi,
    this.warna,
    this.nomorRangka,
    this.catatan,
  });

  final int id;
  final int userId;
  final String nomorPolisi;
  final String merk;
  final String model;
  final int? tahun;
  final String? tipeMesin;
  final String? transmisi;
  final String? warna;
  final String? nomorRangka;
  final String? catatan;

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: _toInt(json['id']) ?? 0,
      userId: _toInt(json['user_id']) ?? 0,
      nomorPolisi: json['nomor_polisi']?.toString() ?? '',
      merk: json['merk']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      tahun: _toInt(json['tahun']),
      tipeMesin: json['tipe_mesin']?.toString(),
      transmisi: json['transmisi']?.toString(),
      warna: json['warna']?.toString(),
      nomorRangka: json['nomor_rangka']?.toString(),
      catatan: json['catatan']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'nomor_polisi': nomorPolisi,
      'merk': merk,
      'model': model,
      'tahun': tahun,
      'tipe_mesin': tipeMesin,
      'transmisi': transmisi,
      'warna': warna,
      'nomor_rangka': nomorRangka,
      'catatan': catatan,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }
}
