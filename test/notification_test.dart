import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mb_engkelqq_mobile/features/notifications/notification_center_page.dart';
import 'package:mb_engkelqq_mobile/models/notification.dart';
import 'package:mb_engkelqq_mobile/providers/notification_provider.dart';
import 'package:mb_engkelqq_mobile/services/notification_service.dart';
import 'package:provider/provider.dart';

class FakeNotificationService extends NotificationService {
  List<AppNotification> fakeItems = [
    const AppNotification(
      id: 1,
      title: 'Booking Dikonfirmasi',
      message: 'Booking Anda telah dikonfirmasi.',
      type: 'booking',
      entityType: 'Booking',
      entityId: 10,
      readAt: null,
      createdAt: '2026-10-08T10:00:00.000000Z',
    ),
    const AppNotification(
      id: 2,
      title: 'Pembayaran Diverifikasi',
      message: 'Pembayaran order #5 diverifikasi.',
      type: 'payment',
      entityType: 'Payment',
      entityId: 5,
      readAt: '2026-10-08T11:00:00.000000Z',
      createdAt: '2026-10-08T10:30:00.000000Z',
    ),
  ];

  @override
  Future<List<AppNotification>> getNotifications() async {
    return fakeItems;
  }

  @override
  Future<List<AppNotification>> getUnreadNotifications() async {
    return fakeItems.where((n) => !n.isReadStatus).toList();
  }

  @override
  Future<AppNotification> markAsRead(int id) async {
    final idx = fakeItems.indexWhere((n) => n.id == id);
    final updated = fakeItems[idx].copyWith(
      readAt: '2026-10-09T01:00:00.000000Z',
      isRead: true,
    );
    fakeItems[idx] = updated;
    return updated;
  }
}

void main() {
  group('Notification Model Tests', () {
    test('parses unread notification correctly', () {
      final json = {
        'id': 60,
        'title': 'Pembayaran Menunggu Verifikasi',
        'message': 'Payment untuk order #6 menunggu verifikasi.',
        'type': 'payment',
        'entity_type': 'ServiceOrder',
        'entity_id': 6,
        'read_at': null,
        'created_at': '2026-10-07T06:00:53.000000Z',
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 60);
      expect(notif.title, 'Pembayaran Menunggu Verifikasi');
      expect(notif.type, 'payment');
      expect(notif.entityType, 'ServiceOrder');
      expect(notif.entityId, 6);
      expect(notif.readAt, isNull);
      expect(notif.isReadStatus, isFalse);
    });

    test('parses read notification correctly', () {
      final json = {
        'id': 23,
        'title': 'Pembayaran Menunggu Verifikasi',
        'message': 'Payment untuk order #4 menunggu verifikasi.',
        'type': 'payment',
        'entity_type': null,
        'entity_id': null,
        'read_at': '2026-10-02T18:55:33.000000Z',
        'created_at': '2026-10-02T18:14:11.000000Z',
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 23);
      expect(notif.readAt, '2026-10-02T18:55:33.000000Z');
      expect(notif.isReadStatus, isTrue);
    });
  });

  group('Notification Provider Tests', () {
    test('loadNotifications sets list and syncs unread count', () async {
      final service = FakeNotificationService();
      final provider = NotificationProvider(notificationService: service);

      final result = await provider.loadNotifications();

      expect(result, isTrue);
      expect(provider.notifications.length, 2);
      expect(provider.unreadCount, 1);
    });

    test('markAsRead updates notification to read', () async {
      final service = FakeNotificationService();
      final provider = NotificationProvider(notificationService: service);

      await provider.loadNotifications();
      expect(provider.unreadCount, 1);

      final success = await provider.markAsRead(1);

      expect(success, isTrue);
      expect(provider.unreadCount, 0);
      expect(provider.notifications.first.isReadStatus, isTrue);
    });
  });

  group('NotificationCenterPage Widget Tests', () {
    testWidgets('renders notifications and filters unread correctly', (
      tester,
    ) async {
      final service = FakeNotificationService();
      final provider = NotificationProvider(notificationService: service);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<NotificationProvider>.value(
            value: provider,
            child: const NotificationCenterPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Booking Dikonfirmasi'), findsOneWidget);
      expect(find.text('Pembayaran Diverifikasi'), findsOneWidget);

      // Tap filter "Belum Dibaca"
      await tester.tap(find.textContaining('Belum Dibaca'));
      await tester.pumpAndSettle();

      expect(find.text('Booking Dikonfirmasi'), findsOneWidget);
      expect(find.text('Pembayaran Diverifikasi'), findsNothing);

      // Tap "Tandai dibaca" on unread notification
      await tester.tap(find.text('Tandai dibaca'));
      await tester.pumpAndSettle();

      // Now all are read
      expect(find.text('Semua notifikasi telah dibaca'), findsOneWidget);
    });
  });
}
