import 'package:flutter_test/flutter_test.dart';
import 'package:mb_engkelqq_mobile/core/constants/api_constants.dart';
import 'package:mb_engkelqq_mobile/models/booking.dart';
import 'package:mb_engkelqq_mobile/models/dashboard.dart';
import 'package:mb_engkelqq_mobile/models/delivery_task.dart';
import 'package:mb_engkelqq_mobile/models/service_item.dart';

void main() {
  group('Audit & Backend Alignment - Model Parsing Tests', () {
    test('DeliveryTask correctly parses Laravel DeliveryTaskResource format', () {
      final json = {
        'id': 10,
        'booking_id': 5,
        'courier_id': 3,
        'task_type': 'pickup',
        'status': 'in_progress',
        'address': 'Jl. Kaliurang KM 12.5, Sleman',
        'distance_km': 6.8,
        'delivery_fee': 25000,
        'started_at': '2026-10-10T08:30:00.000000Z',
        'completed_at': null,
        'notes': 'Tolong hubungi sebelum tiba',
      };

      final task = DeliveryTask.fromJson(json);

      expect(task.id, 10);
      expect(task.bookingId, 5);
      expect(task.courierId, 3);
      expect(task.type, 'pickup');
      expect(task.status, 'in_progress');
      expect(task.address, 'Jl. Kaliurang KM 12.5, Sleman');
      expect(task.resolvedAddress, 'Jl. Kaliurang KM 12.5, Sleman');
      expect(task.distanceKm, 6.8);
      expect(task.deliveryFee, 25000.0);
      expect(task.startedAt, isNotNull);
      expect(task.completedAt, isNull);
    });

    test('DeliveryTask gracefully falls back to pickup_address when address is absent', () {
      final json = {
        'id': 11,
        'booking_id': 6,
        'courier_id': 3,
        'task_type': 'delivery',
        'status': 'completed',
        'pickup_address': 'Jl. Solo KM 9, Sleman',
        'delivery_fee': 30000,
      };

      final task = DeliveryTask.fromJson(json);

      expect(task.id, 11);
      expect(task.pickupAddress, 'Jl. Solo KM 9, Sleman');
      expect(task.resolvedAddress, 'Jl. Solo KM 9, Sleman');
      expect(task.deliveryFee, 30000.0);
    });

    test('Booking correctly parses nested Vehicle object from Laravel backend', () {
      final json = {
        'id': 7,
        'customer_id': 2,
        'vehicle_id': 12,
        'service_type': 'pickup_delivery',
        'complaint': 'Mesin brebet saat tarikan awal',
        'status': 'confirmed',
        'booking_date': '2026-10-10',
        'vehicle': {
          'id': 12,
          'user_id': 2,
          'nomor_polisi': 'AB 1234 CD',
          'merk': 'Honda',
          'model': 'Vario 150',
          'tahun': 2020,
          'transmisi': 'matic',
        },
      };

      final booking = Booking.fromJson(json);

      expect(booking.id, 7);
      expect(booking.customerId, 2);
      expect(booking.vehicleId, 12);
      expect(booking.vehicle, isNotNull);
      expect(booking.vehicle!.nomorPolisi, 'AB 1234 CD');
      expect(booking.vehicle!.licensePlate, 'AB 1234 CD');
      expect(booking.vehicle!.model, 'Vario 150');
      expect(booking.vehicle!.merk, 'Honda');
      expect(booking.vehicle!.brand, 'Honda');
    });

    test('Dashboard correctly parses operational metrics from Laravel Admin dashboard', () {
      final json = {
        'total_bookings': 45,
        'active_bookings': 12,
        'payment_pending': 5,
        'total_service_orders': 20,
        'payment_verified': 15,
        'total_customers': 30,
        'total_vehicles': 35,
      };

      final dashboard = Dashboard.fromJson(json);

      expect(dashboard.totalBookings, 45);
      expect(dashboard.activeBookings, 12);
      expect(dashboard.paymentPending, 5);
      expect(dashboard.totalServiceOrders, 20);
      expect(dashboard.paymentVerified, 15);
      expect(dashboard.totalCustomers, 30);
      expect(dashboard.totalVehicles, 35);
    });

    test('ServiceItem correctly parses master catalog items from backend', () {
      final json = {
        'id': 1,
        'name': 'Oli Mesin Matic 10W-30',
        'price': 55000,
        'category': 'sparepart',
        'description': 'Oli mesin standar matic 800ml',
        'unit': 'botol',
        'stock': 25,
        'is_sparepart': true,
        'is_active': true,
      };

      final item = ServiceItem.fromJson(json);

      expect(item.id, 1);
      expect(item.name, 'Oli Mesin Matic 10W-30');
      expect(item.price, 55000.0);
      expect(item.isSparepart, isTrue);
      expect(item.stock, 25);
      expect(item.isActive, isTrue);
    });

    test('ApiConstants covers complete Laravel routes/api.php endpoint specifications', () {
      expect(ApiConstants.health, '/health');
      expect(ApiConstants.login, '/auth/login');
      expect(ApiConstants.logout, '/auth/logout');
      expect(ApiConstants.me, '/auth/me');
      expect(ApiConstants.vehicles, '/vehicles');
      expect(ApiConstants.bookings, '/bookings');
      expect(ApiConstants.serviceOrders, '/service-orders');
      expect(ApiConstants.serviceItems, '/service-items');
      expect(ApiConstants.payments, '/payments');
      expect(ApiConstants.deliveryTasks, '/delivery-tasks');
      expect(ApiConstants.deliverySettings, '/delivery-settings');
      expect(ApiConstants.paymentSettings, '/payment-settings');
      expect(ApiConstants.invoices, '/invoices');
      expect(ApiConstants.notifications, '/notifications');
      expect(ApiConstants.unreadNotifications, '/notifications/unread');
      expect(ApiConstants.dashboard, '/dashboard');
    });
  });
}

