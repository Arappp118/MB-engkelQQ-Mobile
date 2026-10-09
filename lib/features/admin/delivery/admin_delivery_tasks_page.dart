import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/delivery_task.dart';
import '../../../providers/delivery_provider.dart';

class AdminDeliveryTasksPage extends StatefulWidget {
  const AdminDeliveryTasksPage({super.key});

  @override
  State<AdminDeliveryTasksPage> createState() => _AdminDeliveryTasksPageState();
}

class _AdminDeliveryTasksPageState extends State<AdminDeliveryTasksPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryProvider>().loadDeliveryTasks();
    });
  }

  Future<void> _assignCourier(DeliveryTask task) async {
    final controller = TextEditingController();

    final courierId = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text(
            'Assign Courier',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'ID Courier',
              hintText: 'Contoh: 5',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final id = int.tryParse(controller.text.trim());

                if (id == null || id <= 0) {
                  return;
                }

                Navigator.of(context).pop(id);
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (courierId == null || !mounted) {
      return;
    }

    final provider = context.read<DeliveryProvider>();

    final success = await provider.assignDeliveryTask(
      id: task.id,
      courierId: courierId,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Courier berhasil ditugaskan.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menugaskan courier.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Delivery Tasks'),
        actions: [
          IconButton(
            tooltip: 'Kelola Pembayaran',
            icon: const Icon(Icons.payment_outlined),
            onPressed: () {
              context.push('/admin/payments');
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/admin');
              break;
            case 1:
              context.push('/admin/payments');
              break;
            case 2:
              break;
            case 3:
              context.push('/notifications');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary),
            label: 'Booking',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment, color: AppColors.primary),
            label: 'Pembayaran',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping, color: AppColors.primary),
            label: 'Delivery',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: AppColors.primary),
            label: 'Notifikasi',
          ),
        ],
      ),
      body: Consumer<DeliveryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.deliveryTasks.isEmpty) {
            return const LoadingState(message: 'Memuat data delivery task...');
          }

          if (provider.errorMessage != null && provider.deliveryTasks.isEmpty) {
            return ErrorState(
              message: provider.errorMessage!,
              onRetry: provider.loadDeliveryTasks,
            );
          }

          if (provider.deliveryTasks.isEmpty) {
            return RefreshIndicator(
              onRefresh: provider.loadDeliveryTasks,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'Tidak Ada Tugas',
                    message: 'Belum ada delivery task saat ini.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadDeliveryTasks,
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: provider.deliveryTasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = provider.deliveryTasks[index];

                return _DeliveryTaskCard(
                  task: task,
                  onAssign: () => _assignCourier(task),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DeliveryTaskCard extends StatelessWidget {
  const _DeliveryTaskCard({required this.task, required this.onAssign});

  final DeliveryTask task;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final assigned = task.courierId != null;

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delivery Task #${task.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusBadge(status: task.status ?? '-'),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _InfoRow(label: 'Booking', value: task.bookingId?.toString() ?? '-'),
          _InfoRow(label: 'Type', value: task.type ?? '-'),
          _InfoRow(label: 'Pickup', value: task.pickupAddress ?? '-'),
          _InfoRow(
            label: 'Courier',
            value: task.courierId?.toString() ?? 'Belum ditugaskan',
          ),
          if (task.notes != null && task.notes!.trim().isNotEmpty)
            _InfoRow(label: 'Catatan', value: task.notes!),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: assigned
                    ? AppColors.surface
                    : AppColors.primary,
                foregroundColor: Colors.white,
                side: assigned
                    ? const BorderSide(color: AppColors.primary)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onAssign,
              icon: Icon(assigned ? Icons.edit : Icons.person_add, size: 18),
              label: Text(
                assigned ? 'Ganti Courier' : 'Assign Courier',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
