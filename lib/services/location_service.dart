import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/service_area_constants.dart';
import '../core/constants/workshop_constants.dart';

enum LocationPermissionState { granted, denied, deniedForever, serviceDisabled }

class LocationPermissionResult {
  const LocationPermissionResult({
    required this.state,
    required this.title,
    required this.message,
  });

  final LocationPermissionState state;
  final String title;
  final String message;

  bool get isGranted => state == LocationPermissionState.granted;
}

class ServiceAreaValidationResult {
  const ServiceAreaValidationResult({
    required this.isInsideServiceArea,
    required this.title,
    required this.message,
  });

  final bool isInsideServiceArea;
  final String title;
  final String message;
}

class LocationData {
  const LocationData({
    required this.position,
    this.address,
    this.distanceToWorkshopKm,
    this.isInsideServiceArea = false,
  });

  final Position position;
  final String? address;
  final double? distanceToWorkshopKm;
  final bool isInsideServiceArea;

  double get latitude => position.latitude;
  double get longitude => position.longitude;
}

class LocationServiceException implements Exception {
  LocationServiceException(this.message, {this.title, this.state});

  final String? title;
  final String message;
  final LocationPermissionState? state;

  @override
  String toString() => message;
}

class LocationService {
  LocationService({Geocoding? geocoding}) : _geocodingInstance = geocoding;

  final Geocoding? _geocodingInstance;
  Geocoding get _geocoding => _geocodingInstance ?? Geocoding();

  /// Memeriksa status service GPS dan izin lokasi
  Future<LocationPermissionResult> checkAndRequestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationPermissionResult(
        state: LocationPermissionState.serviceDisabled,
        title: 'GPS Tidak Aktif',
        message: 'Aktifkan layanan lokasi/GPS pada perangkat Anda untuk memeriksa ketersediaan layanan.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationPermissionResult(
        state: LocationPermissionState.denied,
        title: 'Izin Lokasi Diperlukan',
        message: 'Berikan izin lokasi untuk menggunakan layanan pickup.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationPermissionResult(
        state: LocationPermissionState.deniedForever,
        title: 'Izin Lokasi Diperlukan',
        message: 'Izin akses lokasi ditolak permanen. Silakan aktifkan izin lokasi di Pengaturan Aplikasi.',
      );
    }

    return const LocationPermissionResult(
      state: LocationPermissionState.granted,
      title: 'Izin Diberikan',
      message: 'Izin lokasi diberikan.',
    );
  }

  /// Backward-compatibility helper
  Future<bool> checkPermission() async {
    final result = await checkAndRequestPermission();
    return result.isGranted;
  }

  /// Validasi apakah suatu titik koordinat berada di dalam wilayah layanan Kota Tanjungpinang
  ServiceAreaValidationResult validateServiceArea(
    double latitude,
    double longitude,
  ) {
    final isInside = ServiceAreaConstants.isWithinServiceArea(
      latitude,
      longitude,
    );

    if (isInside) {
      return const ServiceAreaValidationResult(
        isInsideServiceArea: true,
        title: 'Wilayah Layanan Terpenuhi',
        message: 'Lokasi berada di dalam wilayah layanan Kota Tanjungpinang, Kepulauan Riau.',
      );
    } else {
      return const ServiceAreaValidationResult(
        isInsideServiceArea: false,
        title: ServiceAreaConstants.outOfAreaTitle,
        message: ServiceAreaConstants.outOfAreaMessage,
      );
    }
  }

  /// Mengambil posisi GPS saat ini
  Future<Position> getCurrentPosition() async {
    final result = await checkAndRequestPermission();

    if (!result.isGranted) {
      throw LocationServiceException(
        result.message,
        title: result.title,
        state: result.state,
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      // Fallback ke last known position jika GPS lambat
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }
      throw LocationServiceException(
        'Lokasi Anda belum dapat ditentukan. Silakan coba lagi.',
        title: 'Lokasi Tidak Tersedia',
      );
    }
  }

  /// Reverse geocoding: Mengonversi koordinat lat/lng menjadi alamat terbaca
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await _geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return null;
      }

      final place = placemarks.first;
      final parts = <String>[
        if (place.street != null && place.street!.trim().isNotEmpty)
          place.street!.trim(),
        if (place.subLocality != null && place.subLocality!.trim().isNotEmpty)
          place.subLocality!.trim(),
        if (place.locality != null && place.locality!.trim().isNotEmpty)
          place.locality!.trim(),
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.trim().isNotEmpty)
          place.subAdministrativeArea!.trim(),
        if (place.administrativeArea != null &&
            place.administrativeArea!.trim().isNotEmpty)
          place.administrativeArea!.trim(),
      ];

      if (parts.isEmpty) {
        return null;
      }

      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  /// Backward-compatibility helper
  Future<String?> getAddressFromPosition(Position position) async {
    return getAddressFromCoordinates(position.latitude, position.longitude);
  }

  /// Forward geocoding: Mengonversi alamat teks menjadi koordinat
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await _geocoding.locationFromAddress(address);
      if (locations.isEmpty) {
        return null;
      }
      final loc = locations.first;
      return Position(
        latitude: loc.latitude,
        longitude: loc.longitude,
        timestamp: loc.timestamp ?? DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Menghitung jarak antara 2 koordinat (hasil dalam km)
  double calculateDistanceKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final distanceInMeters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return distanceInMeters / 1000.0;
  }

  /// Menghitung jarak dari koordinat tertentu ke Bengkel MB-engkelQQ Pusat di Kota Tanjungpinang
  double calculateDistanceToWorkshop(double latitude, double longitude) {
    return calculateDistanceKm(
      latitude,
      longitude,
      WorkshopConstants.workshopLatitude,
      WorkshopConstants.workshopLongitude,
    );
  }

  /// Mengambil data lokasi lengkap saat ini (Posisi + Alamat + Service Area Check)
  Future<LocationData> getCurrentLocationData() async {
    final position = await getCurrentPosition();
    final isInside = ServiceAreaConstants.isWithinServiceArea(
      position.latitude,
      position.longitude,
    );

    final address = await getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    // Hitung jarak ke workshop jika berada di wilayah layanan
    final distanceToWorkshop = isInside
        ? calculateDistanceToWorkshop(position.latitude, position.longitude)
        : null;

    return LocationData(
      position: position,
      address: address,
      distanceToWorkshopKm: distanceToWorkshop,
      isInsideServiceArea: isInside,
    );
  }

  /// Membuka pengaturan aplikasi untuk mengizinkan permission
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  /// Membuka pengaturan lokasi/GPS sistem
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// Membuka aplikasi Google Maps untuk navigasi ke tujuan
  Future<bool> launchNavigation(
    double destinationLatitude,
    double destinationLongitude, {
    String? destinationTitle,
  }) async {
    // 1. Coba Google Navigation intent di Android
    final navUri = Uri.parse(
      'google.navigation:q=$destinationLatitude,$destinationLongitude',
    );
    try {
      if (await canLaunchUrl(navUri)) {
        return await launchUrl(navUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // 2. Fallback: Google Maps web directions URL
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destinationLatitude,$destinationLongitude',
    );
    try {
      if (await canLaunchUrl(webUri)) {
        return await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // 3. Fallback: Geo URI scheme
    final geoUri = Uri.parse(
      'geo:$destinationLatitude,$destinationLongitude?q=$destinationLatitude,$destinationLongitude',
    );
    try {
      if (await canLaunchUrl(geoUri)) {
        return await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    return false;
  }
}
