/// Model titik koordinat sederhana untuk konfigurasi geofence/polygon
class ServiceAreaPoint {
  const ServiceAreaPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Konfigurasi resmi Wilayah Layanan (Service Area) MB-engkelQQ
/// Khusus melayani KOTA TANJUNGPINANG, KEPULAUAN RIAU.
class ServiceAreaConstants {
  ServiceAreaConstants._();

  /// Nama wilayah layanan resmi
  static const String areaName = 'Kota Tanjungpinang';

  /// Nama provinsi wilayah layanan
  static const String provinceName = 'Kepulauan Riau';

  /// Judul pesan ketika lokasi di luar jangkauan
  static const String outOfAreaTitle = 'Di Luar Jangkauan Layanan';

  /// Pesan ketika customer berada di luar wilayah layanan
  static const String outOfAreaMessage =
      'Maaf, layanan bengkel dan pickup MB-engkelQQ saat ini hanya tersedia '
      'di wilayah Kota Tanjungpinang, Kepulauan Riau. Lokasi Anda berada di '
      'luar wilayah layanan.';

  // ===========================================================================
  // BOUNDING BOX KOTA TANJUNGPINANG
  // ===========================================================================
  /// Batas latitude selatan (sekitar Pulau Dompak & Selat Riau)
  static const double minLatitude = 0.8160;

  /// Batas latitude utara (sekitar Senggarang / Sebauk / Madong)
  static const double maxLatitude = 0.9950;

  /// Batas longitude barat (sekitar Tepi Laut / Pelabuhan Sri Bintan Pura)
  static const double minLongitude = 104.4000;

  /// Batas longitude timur (sekitar Bandara RHF / Batu IX-XIV)
  static const double maxLongitude = 104.5750;

  // ===========================================================================
  // POLYGON BOUNDARY ADMINISTRATIF KOTA TANJUNGPINANG
  // Mencakup 4 Kecamatan:
  // 1. Tanjungpinang Kota (Senggarang, Sebauk, Kampung Bugis)
  // 2. Tanjungpinang Barat (Tepi Laut, Teluk Keriting, Bukit Cermin)
  // 3. Tanjungpinang Timur (Air Raja, Batu IX, Melayu Kota Piring, Pinang Kencana)
  // 4. Bukit Bestari (Sei Jang, Dompak, Tanjung Ayun Sakti)
  // ===========================================================================
  static const List<ServiceAreaPoint> administrativePolygon = [
    ServiceAreaPoint(0.9650, 104.4250), // Senggarang Barat
    ServiceAreaPoint(0.9850, 104.4600), // Sebauk Utara
    ServiceAreaPoint(0.9750, 104.5100), // Senggarang Timur / Perbatasan Bintan
    ServiceAreaPoint(0.9600, 104.5500), // Batu 14 / Pinang Kencana Timur
    ServiceAreaPoint(0.9250, 104.5650), // Bandara RHF Timur
    ServiceAreaPoint(0.8800, 104.5550), // Perbatasan Wacopek / Sei Enam
    ServiceAreaPoint(0.8350, 104.5300), // Pulau Dompak Tenggara
    ServiceAreaPoint(0.8200, 104.5000), // Pulau Dompak Barat Daya
    ServiceAreaPoint(0.8450, 104.4500), // Selat Dompak / Teluk Keriting
    ServiceAreaPoint(0.8900, 104.4150), // Pesisir Tepi Laut Selatan
    ServiceAreaPoint(0.9350, 104.4100), // Pelabuhan SBP / Barat
    ServiceAreaPoint(0.9550, 104.4180), // Tanjungpinang Kota Barat
  ];

  /// Memeriksa apakah koordinat (latitude, longitude) berada di dalam
  /// wilayah layanan Kota Tanjungpinang menggunakan algoritma
  /// Point-in-Polygon (Ray Casting) dan Bounding Box filtering.
  static bool isWithinServiceArea(double latitude, double longitude) {
    // 1. Cepat: Bounding box check
    if (latitude < minLatitude || latitude > maxLatitude) {
      return false;
    }
    if (longitude < minLongitude || longitude > maxLongitude) {
      return false;
    }

    // 2. Jika polygon tidak didefinisikan, gunakan bounding box
    if (administrativePolygon.length < 3) {
      return true;
    }

    // 3. Ray Casting Algorithm (Point-in-Polygon)
    bool isInside = false;
    int j = administrativePolygon.length - 1;

    for (int i = 0; i < administrativePolygon.length; i++) {
      final xi = administrativePolygon[i].latitude;
      final yi = administrativePolygon[i].longitude;
      final xj = administrativePolygon[j].latitude;
      final yj = administrativePolygon[j].longitude;

      final intersect =
          ((yi > longitude) != (yj > longitude)) &&
          (latitude < (xj - xi) * (longitude - yi) / (yj - yi) + xi);

      if (intersect) {
        isInside = !isInside;
      }
      j = i;
    }

    return isInside;
  }
}
