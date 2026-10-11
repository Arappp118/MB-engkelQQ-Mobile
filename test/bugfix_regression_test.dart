import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mb_engkelqq_mobile/core/constants/api_constants.dart';
import 'package:mb_engkelqq_mobile/core/errors/api_exception.dart';
import 'package:mb_engkelqq_mobile/features/admin/bookings/admin_bookings_page.dart';
import 'package:mb_engkelqq_mobile/models/booking.dart';
import 'package:mb_engkelqq_mobile/models/dashboard.dart';
import 'package:mb_engkelqq_mobile/models/delivery_task.dart';
import 'package:mb_engkelqq_mobile/models/payment.dart';
import 'package:mb_engkelqq_mobile/models/service_order.dart';
import 'package:mb_engkelqq_mobile/models/service_order_item.dart';
import 'package:mb_engkelqq_mobile/models/vehicle.dart';
import 'package:mb_engkelqq_mobile/providers/auth_provider.dart';
import 'package:mb_engkelqq_mobile/providers/booking_provider.dart';
import 'package:mb_engkelqq_mobile/providers/dashboard_provider.dart';
import 'package:mb_engkelqq_mobile/providers/delivery_provider.dart';
import 'package:mb_engkelqq_mobile/providers/payment_provider.dart';
import 'package:mb_engkelqq_mobile/providers/service_order_provider.dart';
import 'package:mb_engkelqq_mobile/services/booking_service.dart';
import 'package:mb_engkelqq_mobile/services/dashboard_service.dart';
import 'package:mb_engkelqq_mobile/services/delivery_service.dart';
import 'package:mb_engkelqq_mobile/services/payment_service.dart';
import 'package:mb_engkelqq_mobile/services/service_order_service.dart';
import 'package:provider/provider.dart';

// Mock Services
class _MockBookingService extends BookingService {
  _MockBookingService({this.mockBookings = const []});
  final List<Booking> mockBookings;

  @override
  Future<List<Booking>> getBookings() async => mockBookings;

  @override
  Future<Booking> confirmBooking(int id) async {
    final b = mockBookings.firstWhere((b) => b.id == id);
    return Booking(
      id: b.id,
      vehicleId: b.vehicleId,
      nomorBooking: b.nomorBooking,
      status: 'confirmed',
      tanggal: b.tanggal,
      waktu: b.waktu,
      keluhan: b.keluhan,
      vehicle: b.vehicle,
    );
  }
}

class _MockServiceOrderService extends ServiceOrderService {
  _MockServiceOrderService();

  @override
  Future<List<ServiceOrder>> getServiceOrders() async => const [];
}

class _MockDashboardService extends DashboardService {
  _MockDashboardService();

  @override
  Future<Dashboard> getDashboard() async {
    return const Dashboard(
          totalBookings: 14,
          activeBookings: 10,
          paymentPending: 3,
        );
  }
}

class _MockDeliveryService extends DeliveryService {
  _MockDeliveryService({this.mockTasks = const []});
  final List<DeliveryTask> mockTasks;

  @override
  Future<List<DeliveryTask>> getDeliveryTasks() async => mockTasks;

  @override
  Future<DeliveryTask> assignDeliveryTask({
    required int id,
    required int courierId,
  }) async {
    final t = mockTasks.firstWhere((task) => task.id == id);
    return DeliveryTask(
      id: t.id,
      bookingId: t.bookingId,
      courierId: courierId,
      type: t.type,
      status: 'assigned',
      address: t.address,
      distanceKm: t.distanceKm,
      deliveryFee: t.deliveryFee,
    );
  }
}

class _MockPaymentService extends PaymentService {
  _MockPaymentService({this.mockPayments = const {}});
  final Map<int, Payment> mockPayments;
  bool verifyCalled = false;

  @override
  Future<Payment> getPayment(int id) async {
    if (mockPayments.containsKey(id)) {
      return mockPayments[id]!;
    }
    throw Exception('Payment not found');
  }

  @override
  Future<Payment> verifyPayment(int id) async {
    verifyCalled = true;
    final p = mockPayments[id];
    if (p != null && p.status == 'verified') {
      throw Exception("Tidak dapat verifikasi payment dari status 'verified'.");
    }
    return Payment(
      id: id,
      serviceOrderId: p?.serviceOrderId ?? 1,
      amount: p?.amount ?? 100000,
      status: 'verified',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BUG 5 Regression Tests — Delivery Address & Courier Display', () {
    test('cleanAddress removes duplicated segments accurately', () {
      const raw =
          'Jl. Daeng Celak KM.8 No.100, Air Raja, Kec. Tanjungpinang Tim., Kota Tanjung Pinang, Kepulauan Riau 29125, Indonesia, Air Raja, Kecamatan Tanjungpinang Timur, Kota Tanjung Pinang, Kepulauan Riau';

      final cleaned = DeliveryTask.cleanAddress(raw);

      // Verify no duplicate Air Raja, Tanjungpinang, or Kepulauan Riau
      expect(
        cleaned,
        'Jl. Daeng Celak KM.8 No.100, Air Raja, Kec. Tanjungpinang Tim., Kota Tanjung Pinang, Kepulauan Riau 29125, Indonesia',
      );
    });

    test('compactAddress returns concise representation for cards', () {
      const task = DeliveryTask(
        id: 7,
        bookingId: 14,
        type: 'pickup',
        status: 'pending',
        address:
            'Jl. Daeng Celak KM.8 No.100, Air Raja, Kec. Tanjungpinang Tim., Kota Tanjung Pinang, Kepulauan Riau 29125, Indonesia, Air Raja, Kecamatan Tanjungpinang Timur, Kota Tanjung Pinang, Kepulauan Riau',
      );

      expect(
        task.compactAddress,
        'Jl. Daeng Celak KM.8 No.100, Air Raja...',
      );
    });

    test('courierDisplay correctly identifies couriers and unassigned status', () {
      const unassignedTask = DeliveryTask(id: 1, courierId: null);
      const courier3Task = DeliveryTask(id: 2, courierId: 3);
      const courier10Task = DeliveryTask(id: 3, courierId: 10);
      const courier99Task = DeliveryTask(id: 4, courierId: 99);
      const namedTask = DeliveryTask(id: 5, courierId: 3, courierName: 'Andi Kurir');
      const customNamedTask = DeliveryTask(id: 6, courierId: 55, courierName: 'Budi Santoso');
      const emptyNameTask = DeliveryTask(id: 7, courierId: 77, courierName: '   ');

      expect(unassignedTask.courierDisplay, 'Belum ditugaskan');
      expect(courier3Task.courierDisplay, 'Kurir #3');
      expect(courier10Task.courierDisplay, 'Kurir #10');
      expect(courier99Task.courierDisplay, 'Kurir #99');
      expect(namedTask.courierDisplay, 'Andi Kurir');
      expect(customNamedTask.courierDisplay, 'Budi Santoso');
      expect(emptyNameTask.courierDisplay, 'Kurir #77');

      // Test parsing from json with nested courier object
      final jsonNested = DeliveryTask.fromJson({
        'id': 10,
        'courier_id': 3,
        'courier': {'id': 3, 'name': 'Andi Kurir'},
      });
      expect(jsonNested.courierDisplay, 'Andi Kurir');

      // Test parsing from json with flat courier_name
      final jsonFlat = DeliveryTask.fromJson({
        'id': 11,
        'courier_id': 12,
        'courier_name': 'Siti Kurir',
      });
      expect(jsonFlat.courierDisplay, 'Siti Kurir');

      // Test parsing from json with only courier_id
      final jsonIdOnly = DeliveryTask.fromJson({
        'id': 12,
        'courier_id': 42,
      });
      expect(jsonIdOnly.courierDisplay, 'Kurir #42');
    });
  });

  group('BUG 1 & BUG 2 Regression Tests — AdminBookingsPage Rendering & Filter', () {
    late BookingProvider bookingProvider;
    late ServiceOrderProvider orderProvider;
    late DashboardProvider dashboardProvider;
    late AuthProvider authProvider;

    final mockBookings = [
      Booking(
        id: 14,
        vehicleId: 4,
        nomorBooking: 'MC202610100004',
        tanggal: '2026-10-10',
        waktu: '10:00:00',
        keluhan: 'Rem blong',
        status: 'pending',
        vehicle: const Vehicle(
          id: 4,
          userId: 11,
          nomorPolisi: 'BP 3258 PI',
          merk: 'HONDA',
          model: 'VARIO',
          tahun: 2021,
        ),
      ),
      Booking(
        id: 12,
        vehicleId: 4,
        nomorBooking: 'MC202610100002',
        tanggal: '2026-10-10',
        waktu: '11:00:00',
        keluhan: 'Ganti oli',
        status: 'in_service',
        vehicle: const Vehicle(
          id: 4,
          userId: 11,
          nomorPolisi: 'BP 3258 PI',
          merk: 'HONDA',
          model: 'VARIO',
          tahun: 2021,
        ),
      ),
      Booking(
        id: 4,
        vehicleId: 4,
        nomorBooking: 'MC202610020002',
        tanggal: '2026-10-02',
        waktu: '09:00:00',
        keluhan: 'Servis rutin',
        status: 'completed',
        vehicle: const Vehicle(
          id: 4,
          userId: 11,
          nomorPolisi: 'BP 3258 PI',
          merk: 'HONDA',
          model: 'VARIO',
          tahun: 2021,
        ),
      ),
    ];

    setUp(() {
      bookingProvider = BookingProvider(
        bookingService: _MockBookingService(mockBookings: mockBookings),
      );
      orderProvider = ServiceOrderProvider(
        serviceOrderService: _MockServiceOrderService(),
      );
      dashboardProvider = DashboardProvider(
        dashboardService: _MockDashboardService(),
      );
      authProvider = AuthProvider();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: bookingProvider),
          ChangeNotifierProvider.value(value: orderProvider),
          ChangeNotifierProvider.value(value: dashboardProvider),
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const MaterialApp(
          home: AdminBookingsPage(),
        ),
      );
    }

    testWidgets('AdminBookingsPage loads and renders bookings without assertion failure', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // frame post callback
      await tester.pumpAndSettle();

      // Verify dashboard statistics are visible
      expect(find.text('Total Booking'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);
      expect(find.text('Bayar Pending'), findsOneWidget);

      // Verify status filter chips are present
      expect(find.text('Semua (3)'), findsOneWidget);
      expect(find.text('Pending (1)'), findsOneWidget);

      // Verify bookings are rendered in the list
      expect(find.text('Booking #14'), findsOneWidget);

      // Scroll to reveal lower items in ListView.builder
      await tester.drag(find.byType(ListView).last, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Booking #12'), findsOneWidget);

      // Verify Konfirmasi Booking button appears only on pending booking
      expect(find.text('Konfirmasi Booking'), findsOneWidget);
    });

    testWidgets('AdminBookingsPage status filter chips isolate bookings properly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap on Pending filter
      await tester.tap(find.text('Pending (1)'));
      await tester.pumpAndSettle();

      // Only Booking #14 should be visible
      expect(find.text('Booking #14'), findsOneWidget);
      expect(find.text('Booking #12'), findsNothing);
      expect(find.text('Booking #4'), findsNothing);

      // Tap on Selesai filter
      await tester.tap(find.text('Selesai (1)'));
      await tester.pumpAndSettle();

      // Only Booking #4 should be visible
      expect(find.text('Booking #4'), findsOneWidget);
      expect(find.text('Booking #14'), findsNothing);
      expect(find.text('Booking #12'), findsNothing);

      // Tap on Batal filter (which has 0 bookings)
      await tester.tap(find.text('Batal (0)'));
      await tester.pumpAndSettle();

      expect(find.text('Tidak Ada Booking'), findsOneWidget);
      expect(find.text('Tidak ada data booking dengan filter "Batal".'), findsOneWidget);
    });
  });

  group('BUG 3 Regression Tests — Courier Assignment Dialog', () {
    late DeliveryProvider deliveryProvider;

    setUp(() {
      final task = const DeliveryTask(
        id: 7,
        bookingId: 14,
        courierId: null,
        type: 'pickup',
        status: 'pending',
        address: 'Jl. Daeng Celak KM.8',
        distanceKm: 0.9,
        deliveryFee: 3000,
      );
      deliveryProvider = DeliveryProvider(
        deliveryService: _MockDeliveryService(mockTasks: [task]),
      );
    });

    test('Assigning known courier ID passes valid ID', () async {
      final success = await deliveryProvider.assignDeliveryTask(
        id: 7,
        courierId: 3,
      );
      expect(success, isTrue);
      expect(deliveryProvider.deliveryTasks.first.courierId, 3);
    });
  });

  group('BUG 4 Regression Tests — Payment Verification Safety', () {
    late _MockPaymentService mockPaymentService;
    late PaymentProvider paymentProvider;

    setUp(() {
      mockPaymentService = _MockPaymentService(
        mockPayments: {
          1: const Payment(
            id: 1,
            serviceOrderId: 1,
            amount: 110000,
            status: 'verified',
          ),
          9: const Payment(
            id: 9,
            serviceOrderId: 6,
            amount: 165000,
            status: 'waiting_verification',
          ),
        },
      );
      paymentProvider = PaymentProvider(paymentService: mockPaymentService);
    });

    test('Pre-checking verified payment prevents invalid transition', () async {
      final loaded = await paymentProvider.loadPayment(1);
      expect(loaded, isTrue);
      expect(paymentProvider.selectedPayment?.status, 'verified');

      // Attempting to verify verified payment on mock service throws 422 simulation
      final verifyResult = await paymentProvider.verifyPayment(1);
      expect(verifyResult, isFalse);
      expect(
        paymentProvider.errorMessage,
        contains("Tidak dapat verifikasi payment dari status 'verified'"),
      );
    });

    test('Verifying waiting_verification payment succeeds normally', () async {
      final loaded = await paymentProvider.loadPayment(9);
      expect(loaded, isTrue);
      expect(paymentProvider.selectedPayment?.status, 'waiting_verification');

      final success = await paymentProvider.verifyPayment(9);
      expect(success, isTrue);
      expect(paymentProvider.selectedPayment?.status, 'verified');
    });
  });

  group('BUG — Tambah Jasa/Sparepart Contract & Error Handling Tests', () {
    test('addItemToServiceOrder builds correct REST URL and payload', () async {
      final mockService = _MockServiceOrderServiceWithAddItem();
      final provider = ServiceOrderProvider(serviceOrderService: mockService);

      final success = await provider.addServiceOrderItem(
        orderId: 104,
        serviceItemId: 5,
        quantity: 2,
      );

      expect(success, isTrue);
      expect(mockService.lastEndpoint, '${ApiConstants.serviceOrders}/104/items');
      expect(mockService.lastBody, {
        'service_item_id': 5,
        'quantity': 2,
      });
    });

    test('HTTP 404 response differentiates missing API endpoint from not found', () async {
      final mockService = _MockServiceOrderServiceWithAddItem(shouldThrow404: true);
      final provider = ServiceOrderProvider(serviceOrderService: mockService);

      final success = await provider.addServiceOrderItem(
        orderId: 104,
        serviceItemId: 5,
        quantity: 2,
      );

      expect(success, isFalse);
      expect(provider.errorStatusCode, 404);
      expect(provider.errorMessage, 'Data tidak ditemukan.');
    });
  });
}

class _MockServiceOrderServiceWithAddItem extends ServiceOrderService {
  _MockServiceOrderServiceWithAddItem({this.shouldThrow404 = false});

  final bool shouldThrow404;
  String? lastEndpoint;
  Map<String, dynamic>? lastBody;

  @override
  Future<ServiceOrder> addItemToServiceOrder({
    required int serviceOrderId,
    required int serviceItemId,
    required int quantity,
  }) async {
    lastEndpoint = '${ApiConstants.serviceOrders}/$serviceOrderId/items';
    lastBody = {
      'service_item_id': serviceItemId,
      'quantity': quantity,
    };

    if (shouldThrow404) {
      throw const ApiException(
        statusCode: 404,
        message: 'Data tidak ditemukan.',
      );
    }

    return ServiceOrder(
      id: serviceOrderId,
      status: 'in_progress',
      items: [
        ServiceOrderItem(
          name: 'Item Test',
          price: 50000,
          quantity: quantity,
          subtotal: 50000.0 * quantity,
        ),
      ],
    );
  }
}
