import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mb_engkelqq_mobile/core/constants/service_area_constants.dart';
import 'package:mb_engkelqq_mobile/core/constants/workshop_constants.dart';
import 'package:mb_engkelqq_mobile/features/maps/interactive_map_page.dart';
import 'package:mb_engkelqq_mobile/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkshopConstants Tests (Tanjungpinang, Kepulauan Riau)', () {
    test('new workshop coordinates and metadata are correctly configured', () {
      expect(
        WorkshopConstants.workshopName,
        'Jasa Buat Aplikasi, Web, dan Digital Marketing Tanjungpinang CV. ATJ',
      );
      expect(WorkshopConstants.workshopLatitude, 0.9198336);
      expect(WorkshopConstants.workshopLongitude, 104.4930591);
      expect(WorkshopConstants.workshopAddress, contains('Tanjung Pinang'));
      expect(WorkshopConstants.workshopAddress, contains('Kepulauan Riau'));
    });
  });

  group('ServiceAreaConstants & Validation Tests', () {
    test('Workshop Tanjungpinang is inside the official service area', () {
      final isInside = ServiceAreaConstants.isWithinServiceArea(
        WorkshopConstants.workshopLatitude,
        WorkshopConstants.workshopLongitude,
      );
      expect(isInside, isTrue);
    });

    test(
      'Points inside Kota Tanjungpinang are recognized as inside service area',
      () {
        // Tepi Laut / Pelabuhan SBP (~0.9250, 104.4300)
        expect(
          ServiceAreaConstants.isWithinServiceArea(0.9250, 104.4300),
          isTrue,
        );

        // Air Raja / Batu 8 (~0.9200, 104.4900)
        expect(
          ServiceAreaConstants.isWithinServiceArea(0.9200, 104.4900),
          isTrue,
        );

        // Pulau Dompak (~0.8500, 104.5100)
        expect(
          ServiceAreaConstants.isWithinServiceArea(0.8500, 104.5100),
          isTrue,
        );
      },
    );

    test('Points outside Kota Tanjungpinang are rejected by service area', () {
      // Yogyakarta / Luar Tanjungpinang
      expect(
        ServiceAreaConstants.isWithinServiceArea(-7.7956, 110.3695),
        isFalse,
      );

      // Jakarta
      expect(
        ServiceAreaConstants.isWithinServiceArea(-6.2088, 106.8456),
        isFalse,
      );

      // Batam
      expect(
        ServiceAreaConstants.isWithinServiceArea(1.1301, 104.0529),
        isFalse,
      );

      // Mountain View, CA (Android Emulator default)
      expect(
        ServiceAreaConstants.isWithinServiceArea(37.4220, -122.0841),
        isFalse,
      );
    });

    test('outOfArea notification title and message are compliant', () {
      expect(ServiceAreaConstants.outOfAreaTitle, 'Di Luar Jangkauan Layanan');
      expect(
        ServiceAreaConstants.outOfAreaMessage,
        contains(
          'Maaf, layanan bengkel dan pickup MB-engkelQQ saat ini hanya tersedia di wilayah Kota Tanjungpinang, Kepulauan Riau.',
        ),
      );
    });
  });

  group('LocationService Unit Tests', () {
    final locationService = LocationService();

    test(
      'calculateDistanceKm calculates distance between two points accurately',
      () {
        // Workshop (0.9198336, 104.4930591) ke Pelabuhan SBP (0.9272, 104.4447) ~5-6 km
        final distance = locationService.calculateDistanceKm(
          0.9198336,
          104.4930591,
          0.9272,
          104.4447,
        );

        expect(distance, greaterThan(4.5));
        expect(distance, lessThan(7.0));
      },
    );

    test('calculateDistanceToWorkshop returns 0 for workshop itself', () {
      final distance = locationService.calculateDistanceToWorkshop(
        WorkshopConstants.workshopLatitude,
        WorkshopConstants.workshopLongitude,
      );

      expect(distance, closeTo(0.0, 0.001));
    });

    test(
      'validateServiceArea returns correct result for inside and outside',
      () {
        final resultInside = locationService.validateServiceArea(
          0.9198336,
          104.4930591,
        );
        expect(resultInside.isInsideServiceArea, isTrue);

        final resultOutside = locationService.validateServiceArea(
          -6.2088,
          106.8456,
        );
        expect(resultOutside.isInsideServiceArea, isFalse);
        expect(resultOutside.title, ServiceAreaConstants.outOfAreaTitle);
      },
    );

    test('LocationPermissionResult handles states properly', () {
      const granted = LocationPermissionResult(
        state: LocationPermissionState.granted,
        title: 'Izin Diberikan',
        message: 'Izin lokasi diberikan.',
      );
      expect(granted.isGranted, isTrue);

      const denied = LocationPermissionResult(
        state: LocationPermissionState.denied,
        title: 'Izin Lokasi Diperlukan',
        message: 'Berikan izin lokasi untuk menggunakan layanan pickup.',
      );
      expect(denied.isGranted, isFalse);

      const serviceDisabled = LocationPermissionResult(
        state: LocationPermissionState.serviceDisabled,
        title: 'GPS Tidak Aktif',
        message: 'Aktifkan layanan lokasi/GPS pada perangkat Anda untuk memeriksa ketersediaan layanan.',
      );
      expect(serviceDisabled.isGranted, isFalse);
      const deniedForever = LocationPermissionResult(
        state: LocationPermissionState.deniedForever,
        title: 'Izin Lokasi Diperlukan',
        message: 'Izin akses lokasi ditolak permanen. Silakan aktifkan izin lokasi di Pengaturan Aplikasi.',
      );
      expect(deniedForever.isGranted, isFalse);
    });

    test('LocationData model properties return correctly', () {
      final position = Position(
        latitude: 0.9198336,
        longitude: 104.4930591,
        timestamp: DateTime(2026, 1, 1),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      final locationData = LocationData(
        position: position,
        address: 'Jl. Kota Piring No.06, Air Raja',
        distanceToWorkshopKm: 0.0,
        isInsideServiceArea: true,
      );

      expect(locationData.latitude, 0.9198336);
      expect(locationData.longitude, 104.4930591);
      expect(locationData.address, contains('Kota Piring'));
      expect(locationData.distanceToWorkshopKm, 0.0);
      expect(locationData.isInsideServiceArea, isTrue);
    });

    test('LocationServiceException holds title, message, and state', () {
      final exception = LocationServiceException(
        'GPS mati',
        title: 'GPS Tidak Aktif',
        state: LocationPermissionState.serviceDisabled,
      );

      expect(exception.message, 'GPS mati');
      expect(exception.title, 'GPS Tidak Aktif');
      expect(exception.state, LocationPermissionState.serviceDisabled);
      expect(exception.toString(), 'GPS mati');
    });

    test('MapPickerResult stores coordinates and address accurately', () {
      const result = MapPickerResult(
        latitude: 0.9198,
        longitude: 104.4930,
        address: 'Jl. Kota Piring No.06, Air Raja, Tanjungpinang Timur',
        distanceKm: 0.1,
        isInsideServiceArea: true,
      );

      expect(result.latitude, 0.9198);
      expect(result.longitude, 104.4930);
      expect(result.address, contains('Air Raja'));
      expect(result.distanceKm, 0.1);
      expect(result.isInsideServiceArea, isTrue);
    });
  });

  group('InteractiveMapPage Widget Tests', () {
    testWidgets('renders loading state initially in viewer mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InteractiveMapPage(
            mode: MapPageMode.viewer,
            destinationLatitude: 0.9198336,
            destinationLongitude: 104.4930591,
            destinationTitle: 'Workshop Tanjungpinang',
            destinationAddress: 'Jl. Kota Piring, Tanjungpinang',
          ),
        ),
      );

      expect(find.byType(InteractiveMapPage), findsOneWidget);
      expect(find.text('Peta & Navigasi'), findsOneWidget);
    });

    testWidgets('renders loading state initially in picker mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InteractiveMapPage(
            mode: MapPageMode.picker,
            initialLatitude: 0.9198336,
            initialLongitude: 104.4930591,
          ),
        ),
      );

      expect(find.byType(InteractiveMapPage), findsOneWidget);
      expect(find.text('Pilih Lokasi Pickup'), findsOneWidget);
    });

    testWidgets('InteractiveMapPage provides refresh action button in AppBar', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InteractiveMapPage(
            mode: MapPageMode.picker,
            initialLatitude: 0.9198336,
            initialLongitude: 104.4930591,
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
