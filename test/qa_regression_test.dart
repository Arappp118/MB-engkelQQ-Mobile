import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mb_engkelqq_mobile/core/errors/api_exception.dart';
import 'package:mb_engkelqq_mobile/core/widgets/app_buttons.dart';
import 'package:mb_engkelqq_mobile/core/widgets/app_header.dart';
import 'package:mb_engkelqq_mobile/core/widgets/premium_card.dart';
import 'package:mb_engkelqq_mobile/core/widgets/stat_card.dart';
import 'package:mb_engkelqq_mobile/features/customer/bookings/customer_create_booking_page.dart';
import 'package:mb_engkelqq_mobile/features/mechanic/mechanic_dashboard_page.dart';
import 'package:mb_engkelqq_mobile/models/booking.dart';
import 'package:mb_engkelqq_mobile/models/service_order.dart';
import 'package:mb_engkelqq_mobile/models/service_order_item.dart';
import 'package:mb_engkelqq_mobile/models/vehicle.dart';
import 'package:mb_engkelqq_mobile/providers/auth_provider.dart';
import 'package:mb_engkelqq_mobile/providers/booking_provider.dart';
import 'package:mb_engkelqq_mobile/providers/dashboard_provider.dart';
import 'package:mb_engkelqq_mobile/features/courier/courier_dashboard_page.dart';
import 'package:mb_engkelqq_mobile/features/customer/vehicles/vehicle_form_page.dart';
import 'package:mb_engkelqq_mobile/models/delivery_task.dart';
import 'package:mb_engkelqq_mobile/providers/delivery_provider.dart';
import 'package:mb_engkelqq_mobile/providers/invoice_provider.dart';
import 'package:mb_engkelqq_mobile/providers/notification_provider.dart';
import 'package:mb_engkelqq_mobile/providers/payment_provider.dart';
import 'package:mb_engkelqq_mobile/providers/service_order_provider.dart';
import 'package:mb_engkelqq_mobile/providers/vehicle_provider.dart';
import 'package:mb_engkelqq_mobile/services/auth_service.dart';
import 'package:mb_engkelqq_mobile/services/booking_service.dart';
import 'package:mb_engkelqq_mobile/services/delivery_service.dart';
import 'package:mb_engkelqq_mobile/services/service_order_service.dart';
import 'package:mb_engkelqq_mobile/services/vehicle_service.dart';
import 'package:provider/provider.dart';

class MockAuthService extends AuthService {
  bool logoutCalled = false;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<String?> getStoredToken() async => null;

  @override
  Future<String?> getStoredUser() async => null;
}

class FakeBookingService extends BookingService {
  String? lastJenisLayanan;
  Map<String, dynamic>? lastPayload;
  bool shouldThrow422 = false;
  ApiException? errorToThrow;

  @override
  Future<Booking> createBooking({
    required int vehicleId,
    required String tanggal,
    required String waktu,
    required String jenisLayanan,
    required bool pickupRequested,
    String? keluhan,
    String? diagnosisCustomer,
    String? alamatPickup,
    double? estimatedDistanceKm,
    String? catatan,
  }) async {
    if (shouldThrow422) {
      throw errorToThrow ??
          const ApiException(
            message: 'The given data was invalid.\n\njenis_layanan: The selected jenis layanan is invalid.',
            statusCode: 422,
            errors: {
              'jenis_layanan': ['The selected jenis layanan is invalid.'],
            },
          );
    }

    lastJenisLayanan = jenisLayanan;
    lastPayload = {
      'vehicle_id': vehicleId,
      'tanggal': tanggal,
      'waktu': waktu,
      'keluhan': keluhan,
      'diagnosis_customer': diagnosisCustomer,
      'jenis_layanan': jenisLayanan,
      'pickup_requested': pickupRequested,
      'alamat_pickup': alamatPickup,
      'estimated_distance_km': estimatedDistanceKm,
      'catatan': catatan,
    };
    return Booking(
      id: 99,
      vehicleId: vehicleId,
      nomorBooking: 'BK-TEST',
      status: 'pending',
      tanggal: tanggal,
      waktu: waktu,
      jenisLayanan: jenisLayanan,
    );
  }
}

class FakeDeliveryService extends DeliveryService {
  bool shouldThrow = false;
  String errorMessage = 'Tidak dapat memproses delivery task';
  DeliveryTask? currentTask;

  FakeDeliveryService({this.currentTask});

  @override
  Future<DeliveryTask> getDeliveryTask(int id) async {
    return currentTask ??
        DeliveryTask(id: id, status: 'assigned', type: 'pickup');
  }

  @override
  Future<DeliveryTask> startDeliveryTask(int id) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage, statusCode: 422);
    }
    final updated = DeliveryTask(id: id, status: 'in_progress', type: 'pickup');
    currentTask = updated;
    return updated;
  }

  @override
  Future<DeliveryTask> completeDeliveryTask(int id) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage, statusCode: 422);
    }
    final updated = DeliveryTask(id: id, status: 'completed', type: 'pickup');
    currentTask = updated;
    return updated;
  }
}

class FakeVehicleFormService extends VehicleService {
  Map<String, dynamic>? lastCreatedPayload;

  @override
  Future<Vehicle> createVehicle({
    required String nomorPolisi,
    required String merk,
    required String model,
    required int tahun,
    String? tipeMesin,
    String? transmisi,
    String? warna,
    String? nomorRangka,
    String? catatan,
  }) async {
    lastCreatedPayload = {
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
    return Vehicle(
      id: 10,
      userId: 1,
      nomorPolisi: nomorPolisi,
      merk: merk,
      model: model,
      tahun: tahun,
      tipeMesin: tipeMesin,
      transmisi: transmisi,
    );
  }
}

class FakeVehicleService extends VehicleService {
  @override
  Future<List<Vehicle>> getVehicles() async => const [
    Vehicle(
      id: 1,
      userId: 1,
      nomorPolisi: 'BP 1234 AB',
      merk: 'Honda',
      model: 'Vario 150',
    ),
  ];
}

class FakeMechanicServiceOrderService extends ServiceOrderService {
  final Map<int, ServiceOrder> orders;
  bool startCalled = false;
  bool completeCalled = false;
  bool shouldThrow422OnComplete;

  FakeMechanicServiceOrderService({
    required this.orders,
    this.shouldThrow422OnComplete = false,
  });

  @override
  Future<List<ServiceOrder>> getServiceOrders() async {
    return orders.values.toList();
  }

  @override
  Future<ServiceOrder> getServiceOrder(int id) async {
    final order = orders[id];
    if (order == null) {
      throw const ApiException(statusCode: 404, message: 'Not found');
    }
    return order;
  }

  @override
  Future<ServiceOrder> startServiceOrder(int id) async {
    startCalled = true;
    final order = orders[id]!;
    final updated = ServiceOrder(
      id: order.id,
      bookingId: order.bookingId,
      customerId: order.customerId,
      mechanicId: order.mechanicId,
      status: 'in_progress',
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      grandTotal: order.grandTotal,
      diagnosis: order.diagnosis,
      notes: order.notes,
      items: order.items,
    );
    orders[id] = updated;
    return updated;
  }

  @override
  Future<ServiceOrder> completeServiceOrder(int id) async {
    completeCalled = true;
    if (shouldThrow422OnComplete) {
      throw const ApiException(
        statusCode: 422,
        message: 'BR-012: Minimal satu tindakan servis harus dipilih.',
      );
    }
    final order = orders[id]!;
    final updated = ServiceOrder(
      id: order.id,
      bookingId: order.bookingId,
      customerId: order.customerId,
      mechanicId: order.mechanicId,
      status: 'completed',
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      grandTotal: order.grandTotal,
      diagnosis: order.diagnosis,
      notes: order.notes,
      items: order.items,
    );
    orders[id] = updated;
    return updated;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QA Regression - ApiException Error Extraction Tests', () {
    test(
      'extractMessage returns clean message from ApiException with status code',
      () {
        const err401 = ApiException(
          message: 'Email atau password salah.',
          statusCode: 401,
        );
        expect(
          ApiException.extractMessage(err401),
          'Email atau password salah.',
        );

        const err422 = ApiException(
          message: 'Validasi gagal: format email tidak valid.',
          statusCode: 422,
        );
        expect(
          ApiException.extractMessage(err422),
          'Validasi gagal: format email tidak valid.',
        );

        const err500 = ApiException(
          message: 'Terjadi kesalahan pada server.',
          statusCode: 500,
        );
        expect(
          ApiException.extractMessage(err500),
          'Terjadi kesalahan pada server.',
        );
      },
    );

    test('extractMessage cleans raw exception prefixes', () {
      final exc = Exception('Koneksi terputus');
      expect(ApiException.extractMessage(exc), 'Koneksi terputus');

      const socketErr = SocketException('Failed host lookup');
      expect(
        ApiException.extractMessage(socketErr),
        contains('Failed host lookup'),
      );
    });
  });

  group('QA Regression - Mechanic Service Order Status Transition Tests', () {
    Widget buildDetailPage(ServiceOrderProvider provider, int id) {
      return MaterialApp(
        home: ChangeNotifierProvider<ServiceOrderProvider>.value(
          value: provider,
          child: MechanicServiceDetailPage(serviceOrderId: id),
        ),
      );
    }

    testWidgets('pending: tombol mulai servis tersedia dan dapat ditekan', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeService = FakeMechanicServiceOrderService(
        orders: {
          101: const ServiceOrder(
            id: 101,
            bookingId: 10,
            customerId: 1,
            mechanicId: 2,
            status: 'pending',
          ),
        },
      );
      final provider = ServiceOrderProvider(serviceOrderService: fakeService);
      await provider.loadServiceOrder(101);

      await tester.pumpWidget(buildDetailPage(provider, 101));
      await tester.pumpAndSettle();

      expect(find.text('Mulai Service'), findsOneWidget);
      expect(
        find.textContaining('Status service order adalah assigned'),
        findsNothing,
      );
      expect(find.text('Selesaikan Service'), findsNothing);

      await tester.tap(find.text('Mulai Service'));
      await tester.pumpAndSettle();

      expect(fakeService.startCalled, isTrue);
    });

    testWidgets(
      'assigned: banner tampil dan tombol mulai servis tidak tersedia',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeService = FakeMechanicServiceOrderService(
          orders: {
            102: const ServiceOrder(
              id: 102,
              bookingId: 11,
              customerId: 1,
              mechanicId: 2,
              status: 'assigned',
            ),
          },
        );
        final provider = ServiceOrderProvider(serviceOrderService: fakeService);
        await provider.loadServiceOrder(102);

        await tester.pumpWidget(buildDetailPage(provider, 102));
        await tester.pumpAndSettle();

        expect(find.text('Mulai Service'), findsNothing);
        expect(
          find.textContaining('Status service order adalah assigned'),
          findsOneWidget,
        );
        expect(find.text('Selesaikan Service'), findsNothing);
      },
    );

    testWidgets(
      'in_progress dengan item kosong: tombol selesaikan servis nonaktif (BR-012)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeService = FakeMechanicServiceOrderService(
          orders: {
            103: const ServiceOrder(
              id: 103,
              bookingId: 12,
              customerId: 1,
              mechanicId: 2,
              status: 'in_progress',
              diagnosis: 'Pemeriksaan rem dan busi',
              items: [],
            ),
          },
        );
        final provider = ServiceOrderProvider(serviceOrderService: fakeService);
        await provider.loadServiceOrder(103);

        await tester.pumpWidget(buildDetailPage(provider, 103));
        await tester.pumpAndSettle();

        expect(find.text('Mulai Service'), findsNothing);
        expect(find.text('Selesaikan Service'), findsOneWidget);

        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Selesaikan Service'),
        );
        expect(button.onPressed, isNull);

        expect(
          find.textContaining('Belum ada service item/tindakan service'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'in_progress dengan diagnosis dan item: aksi penyelesaian aktif',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeService = FakeMechanicServiceOrderService(
          orders: {
            104: const ServiceOrder(
              id: 104,
              bookingId: 13,
              customerId: 1,
              mechanicId: 2,
              status: 'in_progress',
              diagnosis: 'Ganti oli mesin',
              items: [
                ServiceOrderItem(
                  name: 'Oli MPX 1',
                  price: 55000,
                  quantity: 1,
                  subtotal: 55000,
                ),
              ],
            ),
          },
        );
        final provider = ServiceOrderProvider(serviceOrderService: fakeService);
        await provider.loadServiceOrder(104);

        await tester.pumpWidget(buildDetailPage(provider, 104));
        await tester.pumpAndSettle();

        expect(find.text('Selesaikan Service'), findsOneWidget);

        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Selesaikan Service'),
        );
        expect(button.onPressed, isNotNull);

        await tester.tap(find.text('Selesaikan Service'));
        await tester.pumpAndSettle();

        expect(fakeService.completeCalled, isTrue);
        expect(find.text('Service telah selesai.'), findsOneWidget);
      },
    );

    test('HTTP 422 saat completion: aplikasi tidak menandai order sebagai completed', () async {
      final fakeService = FakeMechanicServiceOrderService(
        orders: {
          105: const ServiceOrder(
            id: 105,
            bookingId: 14,
            customerId: 1,
            mechanicId: 2,
            status: 'in_progress',
            diagnosis: 'Ganti oli',
            items: [],
          ),
        },
        shouldThrow422OnComplete: true,
      );
      final provider = ServiceOrderProvider(serviceOrderService: fakeService);

      await provider.loadServiceOrder(105);
      expect(provider.selectedServiceOrder?.status, 'in_progress');

      final success = await provider.completeServiceOrder(105);
      expect(success, isFalse);

      // Memastikan status tidak berubah ke completed
      expect(provider.selectedServiceOrder?.status, 'in_progress');
      expect(provider.errorMessage, contains('BR-012'));
    });
  });

  group('QA Regression - Session Lifecycle & State Cleanup Tests', () {
    test(
      'authProvider logout invokes all registered provider cleanup callbacks',
      () async {
        final mockAuth = MockAuthService();
        final authProvider = AuthProvider(authService: mockAuth);

        final bookingProvider = BookingProvider();
        final vehicleProvider = VehicleProvider();
        final deliveryProvider = DeliveryProvider();
        final serviceOrderProvider = ServiceOrderProvider();
        final invoiceProvider = InvoiceProvider();
        final paymentProvider = PaymentProvider();
        final notificationProvider = NotificationProvider();
        final dashboardProvider = DashboardProvider();

        bool callbacksInvoked = false;

        authProvider.registerLogoutCallback(() {
          callbacksInvoked = true;
          bookingProvider.clearBookings();
          vehicleProvider.clearVehicles();
          deliveryProvider.clearDeliveryTasks();
          serviceOrderProvider.clearServiceOrders();
          invoiceProvider.clearInvoices();
          paymentProvider.clearPayment();
          notificationProvider.clearNotifications();
          dashboardProvider.clearDashboard();
        });

        await authProvider.logout();

        expect(mockAuth.logoutCalled, isTrue);
        expect(callbacksInvoked, isTrue);
        expect(bookingProvider.bookings, isEmpty);
        expect(vehicleProvider.vehicles, isEmpty);
        expect(deliveryProvider.deliveryTasks, isEmpty);
        expect(serviceOrderProvider.serviceOrders, isEmpty);
        expect(invoiceProvider.invoices, isEmpty);
        expect(notificationProvider.notifications, isEmpty);
        expect(dashboardProvider.dashboard, isNull);
      },
    );
  });

  group('QA Regression - Booking Jenis Layanan Contract Tests', () {
    test('BookingProvider sends verified contract identifiers for each service type', () async {
      const allowedContractValues = {
        'medical_checkup',
        'service_rutin',
        'perbaikan',
      };
      final fakeBookingService = FakeBookingService();
      final provider = BookingProvider(bookingService: fakeBookingService);

      for (final serviceType in allowedContractValues) {
        final success = await provider.createBooking(
          vehicleId: 1,
          tanggal: '2026-10-15',
          waktu: '10:00',
          jenisLayanan: serviceType,
          pickupRequested: false,
          keluhan: 'Pemeriksaan rutin kendaraan',
        );

        expect(success, isTrue);
        expect(fakeBookingService.lastJenisLayanan, serviceType);
        expect(fakeBookingService.lastPayload?['jenis_layanan'], serviceType);
        expect(
          allowedContractValues.contains(fakeBookingService.lastJenisLayanan),
          isTrue,
        );
      }
    });

    testWidgets(
      'CustomerCreateBookingPage dropdown offers exactly the 3 valid contract values and defaults to service_rutin',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final vehicleProvider = VehicleProvider(
          vehicleService: FakeVehicleService(),
        );
        await vehicleProvider.loadVehicles();
        final bookingProvider = BookingProvider(
          bookingService: FakeBookingService(),
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<VehicleProvider>.value(
                value: vehicleProvider,
              ),
              ChangeNotifierProvider<BookingProvider>.value(
                value: bookingProvider,
              ),
            ],
            child: const MaterialApp(home: CustomerCreateBookingPage()),
          ),
        );
        await tester.pumpAndSettle();

        final dropdownFinder = find.byType(DropdownButtonFormField<String>);
        expect(dropdownFinder, findsOneWidget);

        final dropdown = tester.widget<DropdownButtonFormField<String>>(
          dropdownFinder,
        );
        // Memastikan default adalah 'service_rutin' (bukan 'servis_rutin' typo)
        expect(dropdown.initialValue, 'service_rutin');

        // Buka dropdown untuk memverifikasi item yang tersedia
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        // Memastikan 3 opsi kontrak backend tersedia
        expect(find.text('Servis Rutin'), findsWidgets);
        expect(find.text('Perbaikan'), findsWidgets);
        expect(find.text('Medical Checkup'), findsWidgets);

        // Memastikan opsi tidak valid dari backend tidak muncul
        expect(find.text('Tune Up'), findsNothing);
        expect(find.text('Ganti Oli'), findsNothing);
        expect(find.text('Overhaul'), findsNothing);
        expect(find.text('Kelistrikan'), findsNothing);
        expect(find.text('Lainnya'), findsNothing);
      },
    );

    test('BookingProvider handles 422 validation error properly without adding invalid booking to state', () async {
      final fakeBookingService = FakeBookingService()..shouldThrow422 = true;
      final provider = BookingProvider(bookingService: fakeBookingService);

      final success = await provider.createBooking(
        vehicleId: 1,
        tanggal: '2026-10-15',
        waktu: '10:00',
        jenisLayanan: 'service_rutin',
        pickupRequested: false,
        keluhan: 'Rem motor berdecit',
      );

      expect(success, isFalse);
      expect(provider.bookings, isEmpty);
      expect(provider.errorMessage, isNotNull);
      expect(provider.errorMessage, contains('jenis_layanan'));
    });
  });

  group('QA Regression - Courier Delivery Task Error Handling Tests', () {
    testWidgets(
      'CourierDashboardPage shows error message and does not show success when startDeliveryTask fails',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeService = FakeDeliveryService(
          currentTask: const DeliveryTask(
            id: 10,
            status: 'assigned',
            type: 'pickup',
          ),
        )..shouldThrow = true;

        final provider = DeliveryProvider(deliveryService: fakeService);
        await provider.loadDeliveryTask(10);

        await tester.pumpWidget(
          ChangeNotifierProvider<DeliveryProvider>.value(
            value: provider,
            child: const MaterialApp(home: CourierTaskDetailPage(taskId: 10)),
          ),
        );
        await tester.pumpAndSettle();

        // Mulai pickup button should be visible for status assigned
        final startButton = find.text('Mulai Pickup');
        expect(startButton, findsOneWidget);

        await tester.tap(startButton);
        await tester.pumpAndSettle();

        // Sukses tidak boleh ditampilkan saat request gagal
        expect(find.text('Pickup berhasil dimulai.'), findsNothing);
        // Error message harus ditampilkan
        expect(
          find.textContaining('Tidak dapat memproses delivery task'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'CourierDashboardPage shows error message and does not show success when completeDeliveryTask fails',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeService = FakeDeliveryService(
          currentTask: const DeliveryTask(
            id: 11,
            status: 'in_progress',
            type: 'pickup',
          ),
        )..shouldThrow = true;

        final provider = DeliveryProvider(deliveryService: fakeService);
        await provider.loadDeliveryTask(11);

        await tester.pumpWidget(
          ChangeNotifierProvider<DeliveryProvider>.value(
            value: provider,
            child: const MaterialApp(home: CourierTaskDetailPage(taskId: 11)),
          ),
        );
        await tester.pumpAndSettle();

        // Selesaikan pickup button should be visible for in_progress
        final completeButton = find.text('Selesaikan Pickup');
        expect(completeButton, findsOneWidget);

        await tester.tap(completeButton);
        await tester.pumpAndSettle();

        // Sukses tidak boleh ditampilkan saat request gagal
        expect(find.text('Pickup berhasil diselesaikan.'), findsNothing);
        // Error message harus ditampilkan
        expect(
          find.textContaining('Tidak dapat memproses delivery task'),
          findsOneWidget,
        );
      },
    );
  });

  group('QA Regression - Vehicle Contract & Form Tests', () {
    testWidgets(
      'VehicleFormPage provides exact Laravel contract enums for tipe_mesin and transmisi',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeService = FakeVehicleFormService();
        final provider = VehicleProvider(vehicleService: fakeService);

        await tester.pumpWidget(
          ChangeNotifierProvider<VehicleProvider>.value(
            value: provider,
            child: const MaterialApp(home: VehicleFormPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Verifikasi keberadaan form fields
        final dropdowns = find.byType(DropdownButtonFormField<String>);
        expect(dropdowns, findsNWidgets(2));

        final tipeMesinDropdown = tester
            .widget<DropdownButtonFormField<String>>(dropdowns.first);
        final transmisiDropdown = tester
            .widget<DropdownButtonFormField<String>>(dropdowns.last);

        // Verifikasi default contract values
        expect(tipeMesinDropdown.initialValue, '4_tak');
        expect(transmisiDropdown.initialValue, 'matic');

        // Buka dropdown tipe mesin
        await tester.tap(dropdowns.first);
        await tester.pumpAndSettle();

        expect(find.text('4-Tak'), findsWidgets);
        expect(find.text('2-Tak'), findsWidgets);
        expect(find.text('Motor Listrik'), findsWidgets);
      },
    );

    testWidgets(
      'VehicleFormPage submits valid contract enums to VehicleProvider',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeService = FakeVehicleFormService();
        final provider = VehicleProvider(vehicleService: fakeService);

        await tester.pumpWidget(
          ChangeNotifierProvider<VehicleProvider>.value(
            value: provider,
            child: const MaterialApp(home: VehicleFormPage()),
          ),
        );
        await tester.pumpAndSettle();

        // Isi form field wajib
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nomor Polisi (Plat Motor)'),
          'BP 5678 CD',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Merk Kendaraan'),
          'Yamaha',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Model / Tipe'),
          'Aerox 155',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Tahun Pembuatan'),
          '2023',
        );

        final submitButton = find.text('Tambahkan Kendaraan');
        expect(submitButton, findsOneWidget);

        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        expect(fakeService.lastCreatedPayload, isNotNull);
        expect(fakeService.lastCreatedPayload?['nomor_polisi'], 'BP 5678 CD');
        expect(fakeService.lastCreatedPayload?['merk'], 'Yamaha');
        expect(fakeService.lastCreatedPayload?['model'], 'Aerox 155');
        expect(fakeService.lastCreatedPayload?['tahun'], 2023);
        // Memastikan enum kontrak yang dikirim valid dan sesuai aturan backend
        expect(fakeService.lastCreatedPayload?['tipe_mesin'], '4_tak');
        expect(fakeService.lastCreatedPayload?['transmisi'], 'matic');
      },
    );
  });

  group('QA Regression - PremiumCard Widget Integrity Tests', () {
    testWidgets(
      'renders static card without InkWell when onTap is null and provides Material ancestor',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PremiumCard(
                child: Text('Test static card inside PremiumCard'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Test static card inside PremiumCard'),
          findsOneWidget,
        );
        expect(find.byType(InkWell), findsNothing);
        expect(find.byType(Material), findsWidgets);
      },
    );

    testWidgets(
      'renders interactive card with InkWell and triggers onTap callback properly',
      (tester) async {
        bool tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PremiumCard(
                onTap: () {
                  tapped = true;
                },
                child: const Text('Interactive Card Content'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Interactive Card Content'), findsOneWidget);
        expect(find.byType(InkWell), findsOneWidget);

        await tester.tap(find.text('Interactive Card Content'));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      },
    );
  });

  group('QA Regression - UI Layout & Overflow Prevention Tests', () {
    testWidgets(
      'AppAvatarHeader renders directly as PreferredSizeWidget AppBar without overflow',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              appBar: AppAvatarHeader(
                name: 'ridhotest',
                role: 'Customer',
                subtitle: 'Pantau servis & rawat motormu',
                unreadCount: 5,
              ),
              body: SizedBox(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('ridhotest'), findsOneWidget);
        expect(find.text('CUSTOMER'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'AppAvatarHeader renders without overflow under 1.4x system text scaling',
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.4),
            ),
            child: const MaterialApp(
              home: Scaffold(
                appBar: AppAvatarHeader(
                  name: 'ridhotest',
                  role: 'Customer',
                  subtitle: 'Pantau servis & rawat motormu',
                  unreadCount: 10,
                ),
                body: SizedBox(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('CUSTOMER'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'StatCard renders within 140dp height constraint without RenderFlex overflow',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 180,
                  height: 140,
                  child: const StatCard(
                    title: 'Booking Aktif',
                    value: '12',
                    icon: Icons.calendar_month_outlined,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Booking Aktif'), findsOneWidget);
        expect(find.text('12'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'StatCard scales down gracefully under 1.4x text scaling without overflow',
      (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.4),
            ),
            child: MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 170,
                    height: 140,
                    child: const StatCard(
                      title: 'Kendaraan Terdaftar',
                      value: '99',
                      icon: Icons.two_wheeler,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Kendaraan Terdaftar'), findsOneWidget);
        expect(find.text('99'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SecondaryButton handles narrow constraint without horizontal RenderFlex overflow',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 130,
                  height: 48,
                  child: SecondaryButton(
                    text: 'Lokasi Saya (GPS)',
                    icon: Icons.my_location,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Lokasi Saya (GPS)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Three StatCards in a horizontal Row on 360px viewport render without overflow',
      (tester) async {
        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(size: Size(360, 800)),
            child: MaterialApp(
              home: Scaffold(
                body: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Menunggu',
                          value: '14',
                          icon: Icons.access_time,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          title: 'Dikerjakan',
                          value: '3',
                          icon: Icons.timelapse,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: StatCard(
                          title: 'Selesai',
                          value: '52',
                          icon: Icons.check_circle_outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Menunggu'), findsOneWidget);
        expect(find.text('Dikerjakan'), findsOneWidget);
        expect(find.text('Selesai'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
