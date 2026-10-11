import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mb_engkelqq_mobile/core/widgets/status_badge.dart';
import 'package:mb_engkelqq_mobile/models/booking.dart';
import 'package:mb_engkelqq_mobile/models/delivery_task.dart';
import 'package:mb_engkelqq_mobile/models/service_order.dart';
import 'package:mb_engkelqq_mobile/providers/booking_provider.dart';
import 'package:mb_engkelqq_mobile/providers/delivery_provider.dart';
import 'package:mb_engkelqq_mobile/providers/service_order_provider.dart';
import 'package:mb_engkelqq_mobile/services/booking_service.dart';
import 'package:mb_engkelqq_mobile/services/delivery_service.dart';
import 'package:mb_engkelqq_mobile/services/service_order_service.dart';
import 'package:mb_engkelqq_mobile/core/widgets/service_status_timeline.dart';
import 'package:mb_engkelqq_mobile/features/admin/bookings/admin_bookings_page.dart';
import 'package:mb_engkelqq_mobile/features/customer/bookings/customer_booking_detail_page.dart';
import 'package:mb_engkelqq_mobile/features/customer/customer_dashboard_page.dart';
import 'package:mb_engkelqq_mobile/features/courier/courier_dashboard_page.dart';
import 'package:mb_engkelqq_mobile/models/dashboard.dart';
import 'package:mb_engkelqq_mobile/providers/auth_provider.dart';
import 'package:mb_engkelqq_mobile/providers/dashboard_provider.dart';
import 'package:mb_engkelqq_mobile/providers/notification_provider.dart';
import 'package:mb_engkelqq_mobile/services/dashboard_service.dart';

class _FakeBookingService extends BookingService {
  Booking? mockBooking;
  List<Booking> mockBookingsList = [];
  String? lastCancelReason;
  int? lastCancelId;

  bool shouldThrowOnGetBookings = false;

  @override
  Future<List<Booking>> getBookings() async {
    if (shouldThrowOnGetBookings) {
      throw Exception('Koneksi ke backend server gagal (500 Internal Server Error)');
    }
    return mockBookingsList;
  }

  @override
  Future<Booking> getBooking(int id) async {
    return mockBooking ??
        Booking(
          id: id,
          vehicleId: 1,
          status: 'pending',
          pickupRequested: true,
          tanggal: '2026-10-15',
          waktu: '09:00',
        );
  }

  @override
  Future<Booking> cancelBooking(int id, {String? reason}) async {
    lastCancelId = id;
    lastCancelReason = reason;
    final cancelled = Booking(
      id: id,
      vehicleId: mockBooking?.vehicleId ?? 1,
      status: 'cancelled',
      cancellationReason: reason,
      pickupRequested: mockBooking?.pickupRequested,
      tanggal: mockBooking?.tanggal,
      waktu: mockBooking?.waktu,
    );
    mockBooking = cancelled;
    return cancelled;
  }
}

class _FakeDeliveryService extends DeliveryService {
  DeliveryTask? mockTask;
  String? lastNotes;
  int? lastCompleteId;

  @override
  Future<DeliveryTask> getDeliveryTask(int id) async {
    return mockTask ??
        DeliveryTask(
          id: id,
          status: 'completed',
          type: 'pickup',
          bookingId: 100,
          address: 'Jl. Kaliurang KM 5',
        );
  }

  @override
  Future<DeliveryTask> completeDeliveryTask(int id, {String? notes}) async {
    lastCompleteId = id;
    lastNotes = notes;
    final completed = DeliveryTask(
      id: id,
      status: 'completed',
      type: mockTask?.type ?? 'pickup',
      notes: notes,
      bookingId: mockTask?.bookingId ?? 100,
      address: mockTask?.address ?? 'Jl. Kaliurang KM 5',
    );
    mockTask = completed;
    return completed;
  }
}

class _FakeServiceOrderService extends ServiceOrderService {
  List<ServiceOrder> mockOrdersList = [];

  @override
  Future<List<ServiceOrder>> getServiceOrders() async {
    return mockOrdersList;
  }
}

class _FakeDashboardService extends DashboardService {
  Dashboard? mockDashboard;

  @override
  Future<Dashboard> getDashboard() async {
    return mockDashboard ??
        const Dashboard(
          totalBookings: 1,
          activeBookings: 1,
          paymentPending: 0,
          mechanicTotal: 2,
        );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Role Integration - StatusBadge Contract Alignment', () {
    test('StatusBadge maps canonical Laravel Booking Indonesian labels correctly', () {
      expect(StatusBadge.formatStatusLabel('pending'), equals('Menunggu Konfirmasi'));
      expect(StatusBadge.formatStatusLabel('confirmed'), equals('Dikonfirmasi'));
      expect(StatusBadge.formatStatusLabel('waiting_pickup'), equals('Menunggu Pickup'));
      expect(StatusBadge.formatStatusLabel('vehicle_picked_up'), equals('Kendaraan Dijemput'));
      expect(StatusBadge.formatStatusLabel('waiting_service'), equals('Menunggu Servis'));
      expect(StatusBadge.formatStatusLabel('assigned'), equals('Ditugaskan'));
      expect(StatusBadge.formatStatusLabel('in_service'), equals('Sedang Diservis'));
      expect(StatusBadge.formatStatusLabel('service_completed'), equals('Servis Selesai'));
      expect(StatusBadge.formatStatusLabel('waiting_payment'), equals('Menunggu Pembayaran'));
      expect(StatusBadge.formatStatusLabel('waiting_verification'), equals('Menunggu Verifikasi'));
      expect(StatusBadge.formatStatusLabel('paid'), equals('Dibayar'));
      expect(StatusBadge.formatStatusLabel('ready_for_delivery'), equals('Siap Diambil/Diantar'));
      expect(StatusBadge.formatStatusLabel('completed'), equals('Selesai'));
      expect(StatusBadge.formatStatusLabel('cancelled'), equals('Dibatalkan'));
      expect(StatusBadge.formatStatusLabel('rejected'), equals('Ditolak'));
    });
  });

  group('Role Integration - Customer Booking & Cancellation', () {
    test('BookingService and Provider cancelBooking handles cancellation reason correctly', () async {
      final fakeService = _FakeBookingService();
      final provider = BookingProvider(bookingService: fakeService);

      final success = await provider.cancelBooking(12, reason: 'Tidak jadi servis');
      expect(success, isTrue);
      expect(fakeService.lastCancelId, equals(12));
      expect(fakeService.lastCancelReason, equals('Tidak jadi servis'));
    });

    testWidgets('CustomerBookingDetailPage displays Batalkan Booking button for pending booking', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeBookingService = _FakeBookingService()
        ..mockBooking = const Booking(
          id: 55,
          vehicleId: 1,
          status: 'pending',
          pickupRequested: true,
          tanggal: '2026-10-15',
          waktu: '09:00',
        );
      final bookingProvider = BookingProvider(bookingService: fakeBookingService);
      final serviceOrderProvider = ServiceOrderProvider(serviceOrderService: _FakeServiceOrderService());

      await bookingProvider.loadBooking(55);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
            ChangeNotifierProvider<ServiceOrderProvider>.value(value: serviceOrderProvider),
          ],
          child: const MaterialApp(
            home: CustomerBookingDetailPage(bookingId: 55),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Batalkan Booking'), findsOneWidget);
    });

    testWidgets('CustomerBookingDetailPage displays pickup lifecycle notice when vehicle_picked_up', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeBookingService = _FakeBookingService()
        ..mockBooking = const Booking(
          id: 60,
          vehicleId: 1,
          status: 'vehicle_picked_up',
          pickupRequested: true,
          tanggal: '2026-10-15',
          waktu: '10:00',
        );
      final bookingProvider = BookingProvider(bookingService: fakeBookingService);
      final serviceOrderProvider = ServiceOrderProvider(serviceOrderService: _FakeServiceOrderService());

      await bookingProvider.loadBooking(60);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
            ChangeNotifierProvider<ServiceOrderProvider>.value(value: serviceOrderProvider),
          ],
          child: const MaterialApp(
            home: CustomerBookingDetailPage(bookingId: 60),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Motor Dalam Perjalanan ke Bengkel'), findsOneWidget);
      expect(find.textContaining('Kendaraan telah dijemput Kurir dan diserahterimakan ke bengkel'), findsOneWidget);
      expect(find.textContaining('Menunggu sistem bengkel menugaskan mekanik'), findsOneWidget);
      // Cancellation button should be absent because status is vehicle_picked_up (only pending/confirmed can cancel)
      expect(find.text('Batalkan Booking'), findsNothing);
      expect(find.textContaining('Mekanik #'), findsNothing);
    });
  });

  group('Role Integration - Courier Task Operations & Scoping', () {
    test('DeliveryService and Provider completeDeliveryTask passes notes correctly', () async {
      final fakeDeliveryService = _FakeDeliveryService();
      final deliveryProvider = DeliveryProvider(deliveryService: fakeDeliveryService);

      final success = await deliveryProvider.completeDeliveryTask(44, notes: 'Motor telah dijemput aman');
      expect(success, isTrue);
      expect(fakeDeliveryService.lastCompleteId, equals(44));
      expect(fakeDeliveryService.lastNotes, equals('Motor telah dijemput aman'));
    });

    testWidgets('CourierTaskDetailPage shows operational workshop explanation when pickup task is completed', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeDeliveryService = _FakeDeliveryService()
        ..mockTask = const DeliveryTask(
          id: 77,
          status: 'completed',
          type: 'pickup',
          bookingId: 100,
          address: 'Jl. Kaliurang KM 5',
        );
      final deliveryProvider = DeliveryProvider(deliveryService: fakeDeliveryService);

      await deliveryProvider.loadDeliveryTask(77);

      await tester.pumpWidget(
        ChangeNotifierProvider<DeliveryProvider>.value(
          value: deliveryProvider,
          child: const MaterialApp(
            home: CourierTaskDetailPage(taskId: 77),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Informasi Alur Bengkel'), findsOneWidget);
      expect(find.textContaining('secara otomatis memproses kedatangan unit ke antrean servis atau penugasan mekanik'), findsOneWidget);
      // Courier does not have mechanic assignment controls
      expect(find.textContaining('Tugaskan Mekanik'), findsNothing);
    });
  });

  group('Role Integration - Admin Arrival Confirmation & Refresh Actions', () {
    testWidgets('AdminBookingsPage displays native pickup handling and status refresh without forcing web arrival', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeBookingService = _FakeBookingService()
        ..mockBookingsList = [
          Booking(
            id: 88,
            nomorBooking: 'BK-88',
            vehicleId: 1,
            status: 'vehicle_picked_up',
            pickupRequested: true,
            alamatPickup: 'Jl. Malioboro No. 1',
            tanggal: '2026-10-15',
            waktu: '10:00',
          ),
        ];
      final bookingProvider = BookingProvider(bookingService: fakeBookingService);
      final orderProvider = ServiceOrderProvider(serviceOrderService: _FakeServiceOrderService());
      final dashProvider = DashboardProvider(dashboardService: _FakeDashboardService());
      final authProvider = AuthProvider();

      await bookingProvider.loadBookings();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
            ChangeNotifierProvider<ServiceOrderProvider>.value(value: orderProvider),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(
            home: AdminBookingsPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Motor Sudah Dijemput Kurir'), findsOneWidget);
      expect(find.text('Periksa Pembaruan Status'), findsOneWidget);
      expect(find.textContaining('Menunggu sistem backend memproses penugasan mekanik'), findsOneWidget);
      // Verify no web arrival button or requirement
      expect(find.text('Buka Konfirmasi Kedatangan'), findsNothing);
      expect(find.text('Konfirmasi Booking'), findsNothing);
      expect(find.textContaining('Mekanik #'), findsNothing);
    });

    testWidgets('AdminBookingsPage Periksa Pembaruan Status syncs status from API when backend remains vehicle_picked_up', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeBookingService = _FakeBookingService()
        ..mockBookingsList = [
          Booking(
            id: 88,
            nomorBooking: 'BK-88',
            vehicleId: 1,
            status: 'vehicle_picked_up',
            pickupRequested: true,
            tanggal: '2026-10-15',
            waktu: '10:00',
          ),
        ];
      final bookingProvider = BookingProvider(bookingService: fakeBookingService);
      final orderProvider = ServiceOrderProvider(serviceOrderService: _FakeServiceOrderService());
      final dashProvider = DashboardProvider(dashboardService: _FakeDashboardService());
      final authProvider = AuthProvider();

      await bookingProvider.loadBookings();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
            ChangeNotifierProvider<ServiceOrderProvider>.value(value: orderProvider),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(
            home: AdminBookingsPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Periksa Pembaruan Status
      await tester.tap(find.text('Periksa Pembaruan Status'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Status booking #88 dari server masih "vehicle_picked_up"'), findsOneWidget);
      expect(find.textContaining('Menunggu pembaruan penugasan mekanik dari sistem backend'), findsOneWidget);
      expect(find.text('Buka Konfirmasi Kedatangan'), findsNothing);
      expect(find.textContaining('Mekanik #'), findsNothing);
    });

    testWidgets('AdminBookingsPage Periksa Pembaruan Status handles API error response gracefully', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeBookingService = _FakeBookingService()
        ..mockBookingsList = [
          Booking(
            id: 88,
            nomorBooking: 'BK-88',
            vehicleId: 1,
            status: 'vehicle_picked_up',
            pickupRequested: true,
            tanggal: '2026-10-15',
            waktu: '10:00',
          ),
        ];
      final bookingProvider = BookingProvider(bookingService: fakeBookingService);
      final orderProvider = ServiceOrderProvider(serviceOrderService: _FakeServiceOrderService());
      final dashProvider = DashboardProvider(dashboardService: _FakeDashboardService());
      final authProvider = AuthProvider();

      await bookingProvider.loadBookings();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
            ChangeNotifierProvider<ServiceOrderProvider>.value(value: orderProvider),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(
            home: AdminBookingsPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Enable error on next fetch
      fakeBookingService.shouldThrowOnGetBookings = true;

      // Tap Periksa Pembaruan Status
      await tester.tap(find.text('Periksa Pembaruan Status'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Gagal memeriksa pembaruan status'), findsOneWidget);
    });

    testWidgets('AdminBookingsPage Periksa Pembaruan Status updates booking to assigned and reveals assigned mechanic when backend updates', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeBookingService = _FakeBookingService()
        ..mockBookingsList = [
          Booking(
            id: 88,
            nomorBooking: 'BK-88',
            vehicleId: 1,
            status: 'vehicle_picked_up',
            pickupRequested: true,
            tanggal: '2026-10-15',
            waktu: '10:00',
          ),
        ];
      final fakeOrderService = _FakeServiceOrderService();
      final bookingProvider = BookingProvider(bookingService: fakeBookingService);
      final orderProvider = ServiceOrderProvider(serviceOrderService: fakeOrderService);
      final dashProvider = DashboardProvider(dashboardService: _FakeDashboardService());
      final authProvider = AuthProvider();

      await bookingProvider.loadBookings();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
            ChangeNotifierProvider<ServiceOrderProvider>.value(value: orderProvider),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(
            home: AdminBookingsPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Motor Sudah Dijemput Kurir'), findsOneWidget);

      // Simulate backend state after arrive/transition: status -> assigned, service order created
      fakeBookingService.mockBookingsList = [
        Booking(
          id: 88,
          nomorBooking: 'BK-88',
          vehicleId: 1,
          status: 'assigned',
          pickupRequested: true,
          tanggal: '2026-10-15',
          waktu: '10:00',
        ),
      ];
      fakeOrderService.mockOrdersList = [
        const ServiceOrder(
          id: 1,
          bookingId: 88,
          mechanicId: 5,
          status: 'pending',
        ),
      ];

      // Tap Periksa Pembaruan Status
      await tester.tap(find.text('Periksa Pembaruan Status'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Status booking #88 berhasil diperbarui: "assigned"'), findsOneWidget);
      expect(find.textContaining('Mekanik #5 telah ditugaskan'), findsOneWidget);
      expect(find.text('Mekanik #5'), findsOneWidget);
      expect(find.text('Motor Sudah Dijemput Kurir'), findsNothing);
    });

    testWidgets('AdminBookingsPage displays waiting_pickup with direct link to Delivery Tasks', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeBookingService = _FakeBookingService()
        ..mockBookingsList = [
          Booking(
            id: 87,
            nomorBooking: 'BK-87',
            vehicleId: 1,
            status: 'waiting_pickup',
            pickupRequested: true,
            alamatPickup: 'Jl. Malioboro No. 5',
            tanggal: '2026-10-15',
            waktu: '10:00',
          ),
        ];
      final bookingProvider = BookingProvider(bookingService: fakeBookingService);
      final orderProvider = ServiceOrderProvider(serviceOrderService: _FakeServiceOrderService());
      final dashProvider = DashboardProvider(dashboardService: _FakeDashboardService());
      final authProvider = AuthProvider();

      await bookingProvider.loadBookings();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
            ChangeNotifierProvider<ServiceOrderProvider>.value(value: orderProvider),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(
            home: AdminBookingsPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Menunggu Kurir memulai penjemputan unit'), findsOneWidget);
      expect(find.text('Lihat Penugasan di Delivery Tasks'), findsOneWidget);
    });

    testWidgets('AdminBookingsPage displays waiting_service operational card and Periksa Pembaruan Status button', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeBookingService = _FakeBookingService()
        ..mockBookingsList = [
          Booking(
            id: 89,
            nomorBooking: 'BK-89',
            vehicleId: 1,
            status: 'waiting_service',
            pickupRequested: true,
            tanggal: '2026-10-15',
            waktu: '10:00',
          ),
        ];
      final bookingProvider = BookingProvider(bookingService: fakeBookingService);
      final orderProvider = ServiceOrderProvider(serviceOrderService: _FakeServiceOrderService());
      final dashProvider = DashboardProvider(dashboardService: _FakeDashboardService());
      final authProvider = AuthProvider();

      await bookingProvider.loadBookings();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
            ChangeNotifierProvider<ServiceOrderProvider>.value(value: orderProvider),
            ChangeNotifierProvider<DashboardProvider>.value(value: dashProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(
            home: AdminBookingsPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Kendaraan Tiba di Bengkel (Antrean Servis)'), findsOneWidget);
      expect(find.textContaining('menunggu alokasi mekanik yang tersedia'), findsOneWidget);
      expect(find.text('Periksa Pembaruan Status'), findsOneWidget);

      // Tap Periksa Pembaruan Status to verify server sync
      await tester.tap(find.text('Periksa Pembaruan Status'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Status booking #89 berhasil diperbarui: "waiting_service"'), findsOneWidget);
    });
  });

  group('Role Integration - Timeline & Customer Pickup Status Lifecycle', () {
    testWidgets('ServiceStatusTimeline with vehicle_picked_up stays on stage 2 (Dikonfirmasi) and does not show Pengerjaan as active', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServiceStatusTimeline(currentStatus: 'vehicle_picked_up'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tahap 2 dari 4'), findsOneWidget);
      expect(find.textContaining('Pengerjaan servis belum dimulai'), findsOneWidget);
    });

    testWidgets('ServiceStatusTimeline with waiting_service displays informative workshop queue note', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServiceStatusTimeline(currentStatus: 'waiting_service'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tahap 2 dari 4'), findsOneWidget);
      expect(find.textContaining('Kendaraan telah tiba di bengkel dan masuk antrean servis sambil menunggu mekanik tersedia.'), findsOneWidget);
    });

    testWidgets('CustomerDashboardPage displays derived pickup status in timeline when active booking is vehicle_picked_up', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeDashboardService = _FakeDashboardService()
        ..mockDashboard = const Dashboard(
          activeBookings: 1,
          activeServiceOrders: 0,
          recentBookings: [
            {'id': 14, 'nomor_booking': 'MC202610100004', 'status': 'vehicle_picked_up'},
          ],
        );
      final dashProvider = DashboardProvider(dashboardService: fakeDashboardService);
      final notifProvider = NotificationProvider();
      final authProvider = AuthProvider();

      await dashProvider.loadDashboard();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DashboardProvider>.value(value: dashProvider),
            ChangeNotifierProvider<NotificationProvider>.value(value: notifProvider),
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const MaterialApp(
            home: CustomerDashboardPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Status Penjemputan Motor'), findsOneWidget);
      expect(find.textContaining('tahap servis belum dimulai'), findsOneWidget);
      expect(find.text('Tahap 2 dari 4'), findsOneWidget);
    });
  });
}
