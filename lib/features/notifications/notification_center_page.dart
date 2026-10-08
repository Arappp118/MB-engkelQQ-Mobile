import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification.dart';
import '../../providers/notification_provider.dart';
import '../customer/bookings/customer_booking_detail_page.dart';
import '../customer/service_orders/customer_service_order_detail_page.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage> {
  int _selectedFilterIndex = 0; // 0 = Semua, 1 = Belum Dibaca

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<NotificationProvider>();
    await provider.loadNotifications();
    await provider.loadUnreadNotifications();
  }

  void _onNotificationTap(AppNotification item) async {
    final provider = context.read<NotificationProvider>();

    if (!item.isReadStatus) {
      await provider.markAsRead(item.id);
    }

    if (!mounted) return;

    if (item.entityType == 'ServiceOrder' && item.entityId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              CustomerServiceOrderDetailPage(serviceOrderId: item.entityId!),
        ),
      );
    } else if (item.entityType == 'Booking' && item.entityId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CustomerBookingDetailPage(bookingId: item.entityId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              final unreadCount = provider.unreadCount;
              if (unreadCount == 0) return const SizedBox.shrink();

              return TextButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.markAllAsRead(),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Tandai Dibaca'),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          final allList = provider.notifications;
          final unreadList = allList.where((n) => !n.isReadStatus).toList();
          final displayList = _selectedFilterIndex == 0 ? allList : unreadList;

          if (provider.isLoading && allList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && allList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal memuat notifikasi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(provider.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('Semua (${allList.length})'),
                      selected: _selectedFilterIndex == 0,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilterIndex = 0);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Belum Dibaca (${unreadList.length})'),
                      selected: _selectedFilterIndex == 1,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilterIndex = 1);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  child: displayList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Icon(
                              _selectedFilterIndex == 1
                                  ? Icons.mark_email_read_outlined
                                  : Icons.notifications_none_outlined,
                              size: 72,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedFilterIndex == 1
                                  ? 'Semua notifikasi telah dibaca'
                                  : 'Belum ada notifikasi',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFilterIndex == 1
                                  ? 'Tidak ada notifikasi baru saat ini.'
                                  : 'Pemberitahuan aktivitas servis akan muncul di sini.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: displayList.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = displayList[index];
                            return _NotificationCard(
                              notification: item,
                              onTap: () => _onNotificationTap(item),
                              onMarkRead: () => provider.markAsRead(item.id),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onMarkRead,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  IconData _getIcon(String? type) {
    switch (type) {
      case 'payment':
        return Icons.payments_outlined;
      case 'booking':
        return Icons.calendar_month_outlined;
      case 'service_order':
        return Icons.build_outlined;
      case 'delivery_task':
        return Icons.local_shipping_outlined;
      case 'job':
        return Icons.engineering_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(BuildContext context, String? type) {
    switch (type) {
      case 'payment':
        return Colors.green;
      case 'booking':
        return Colors.blue;
      case 'service_order':
        return Colors.orange;
      case 'delivery_task':
        return Colors.purple;
      case 'job':
        return Colors.teal;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$min';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isReadStatus;
    final color = _getIconColor(context, notification.type);

    return Card(
      elevation: isUnread ? 2 : 0,
      color: isUnread
          ? Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnread
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: 0.3),
                width: 1.5,
              )
            : BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(notification.type),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title ?? 'Pemberitahuan',
                            style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        if (isUnread)
                          InkWell(
                            onTap: onMarkRead,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.done,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Tandai dibaca',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
