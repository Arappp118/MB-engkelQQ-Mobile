import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/premium_card.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: AppColors.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
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
            return const LoadingState(
              height: 350,
              message: 'Memuat notifikasi...',
            );
          }

          if (provider.errorMessage != null && allList.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 60),
                  ErrorState(
                    title: 'Gagal Memuat Notifikasi',
                    message: provider.errorMessage!,
                    onRetry: _loadData,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('Semua (${allList.length})'),
                      selected: _selectedFilterIndex == 0,
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: TextStyle(
                        color: _selectedFilterIndex == 0
                            ? AppColors.primaryLight
                            : AppColors.textSecondary,
                        fontWeight: _selectedFilterIndex == 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
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
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: TextStyle(
                        color: _selectedFilterIndex == 1
                            ? AppColors.primaryLight
                            : AppColors.textSecondary,
                        fontWeight: _selectedFilterIndex == 1
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilterIndex = 1);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.borderSubtle, height: 1),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surfaceCard,
                  onRefresh: _loadData,
                  child: displayList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            EmptyState(
                              icon: _selectedFilterIndex == 1
                                  ? Icons.mark_email_read_outlined
                                  : Icons.notifications_none_outlined,
                              title: _selectedFilterIndex == 1
                                  ? 'Semua notifikasi telah dibaca'
                                  : 'Belum ada notifikasi',
                              message: _selectedFilterIndex == 1
                                  ? 'Tidak ada notifikasi baru saat ini.'
                                  : 'Pemberitahuan aktivitas servis akan muncul di sini.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: displayList.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
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

  Color _getIconColor(String? type) {
    switch (type) {
      case 'payment':
        return AppColors.success;
      case 'booking':
        return AppColors.secondary;
      case 'service_order':
        return AppColors.primary;
      case 'delivery_task':
        return AppColors.warning;
      case 'job':
        return AppColors.info;
      default:
        return AppColors.primary;
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
    final color = _getIconColor(notification.type);

    return PremiumCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: isUnread
          ? AppColors.surfaceCardElevated
          : AppColors.surfaceCard,
      borderColor: isUnread
          ? AppColors.primary.withValues(alpha: 0.4)
          : AppColors.border,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getIcon(notification.type), color: color, size: 22),
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
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (isUnread)
                      InkWell(
                        onTap: onMarkRead,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.done,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Tandai dibaca',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
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
    );
  }
}
