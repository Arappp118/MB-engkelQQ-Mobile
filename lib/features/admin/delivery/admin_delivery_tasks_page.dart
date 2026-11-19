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
    final courierId = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => _AssignCourierDialog(task: task),
    );

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
      await provider.loadDeliveryTasks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kurir #$courierId berhasil ditugaskan ke Task #${task.id}.',
          ),
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
              context.go('/admin/payments');
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
              context.go('/admin/payments');
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
          _InfoRow(label: 'Booking', value: '#${task.bookingId ?? '-'}'),
          _InfoRow(label: 'Type', value: (task.type ?? '-').toUpperCase()),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 90,
                  child: Text(
                    'Alamat',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.compactAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      if (task.resolvedAddress != null &&
                          task.resolvedAddress != '-')
                        InkWell(
                          onTap: () => _showAddressDetails(context, task),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              'Lihat Detail Alamat Lengkap →',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (task.distanceKm != null)
            _InfoRow(
              label: 'Jarak',
              value: '${task.distanceKm!.toStringAsFixed(1)} km',
            ),
          if (task.deliveryFee != null)
            _InfoRow(
              label: 'Ongkir',
              value: 'Rp ${task.deliveryFee!.round()}',
            ),
          _InfoRow(
            label: 'Courier',
            value: task.courierDisplay,
          ),
          if (task.notes != null && task.notes!.trim().isNotEmpty)
            _InfoRow(label: 'Catatan', value: task.notes!),
          if (task.status == 'completed') ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Tugas Selesai',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (task.status == 'cancelled') ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Tugas Dibatalkan',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
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
        ],
      ),
    );
  }

  void _showAddressDetails(BuildContext context, DeliveryTask task) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Detail Alamat Task #${task.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.border),
              const SizedBox(height: 8),
              const Text(
                'Alamat Lengkap (Deduplikasi):',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                task.resolvedAddress ?? '-',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              if (task.distanceKm != null || task.deliveryFee != null) ...[
                Row(
                  children: [
                    if (task.distanceKm != null)
                      Text(
                        'Estimasi Jarak: ${task.distanceKm!.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    if (task.distanceKm != null && task.deliveryFee != null)
                      const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                    if (task.deliveryFee != null)
                      Text(
                        'Ongkir: Rp ${task.deliveryFee!.round()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignCourierDialog extends StatefulWidget {
  const _AssignCourierDialog({required this.task});

  final DeliveryTask task;

  @override
  State<_AssignCourierDialog> createState() => _AssignCourierDialogState();
}

class _AssignCourierDialogState extends State<_AssignCourierDialog> {
  int? _selectedCourierId;
  final _manualController = TextEditingController();
  bool _isManual = false;
  String? _validationError;

  // Known couriers in database seeder
  final _knownCouriers = const [
    {'id': 3, 'name': 'Andi Kurir', 'email': 'kurir@motocare.test'},
    {'id': 10, 'name': 'Kurir SPX', 'email': 'spx123@gmail.com'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.task.courierId != null) {
      final isKnown = _knownCouriers.any((c) => c['id'] == widget.task.courierId);
      if (isKnown) {
        _selectedCourierId = widget.task.courierId;
      } else {
        _isManual = true;
        _manualController.text = widget.task.courierId.toString();
      }
    } else {
      _selectedCourierId = null; // Do NOT auto-assume courier ID without explicit admin selection
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  void _submit() {
    int? finalId;
    if (_isManual) {
      final text = _manualController.text.trim();
      final parsed = int.tryParse(text);
      if (parsed == null || parsed <= 0) {
        setState(() {
          _validationError = 'ID Kurir harus berupa angka bulat positif (> 0).';
        });
        return;
      }
      finalId = parsed;
    } else {
      finalId = _selectedCourierId;
      if (finalId == null) {
        setState(() {
          _validationError = 'Silakan pilih salah satu kurir referensi atau gunakan ID manual.';
        });
        return;
      }
    }

    Navigator.of(context).pop(finalId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      actionsOverflowButtonSpacing: 8,
      title: Row(
        children: [
          const Icon(Icons.person_pin_circle_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Assign Courier Task #${widget.task.id}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Catatan: Backend Laravel API v1 tidak menyediakan endpoint daftar kurir dinamis. Pilihan di bawah merupakan referensi seeder awal sistem. Pastikan akun kurir aktif pada database backend yang sedang berjalan sebelum menugaskan.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Pilihan Kurir Referensi Sistem (Seeder Awal):',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ..._knownCouriers.map((courier) {
              final id = courier['id'] as int;
              final name = courier['name'] as String;
              final email = courier['email'] as String;
              final isSelected = !_isManual && _selectedCourierId == id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      _isManual = false;
                      _selectedCourierId = id;
                      _validationError = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryContainer.withValues(alpha: 0.3)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$name (ID: $id)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                email,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  setState(() {
                    _isManual = true;
                    _validationError = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _isManual
                        ? AppColors.primaryContainer.withValues(alpha: 0.3)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isManual ? AppColors.primary : AppColors.border,
                      width: _isManual ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isManual
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _isManual
                            ? AppColors.primary
                            : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ID Kurir Lain (Manual)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Masukkan ID angka secara manual',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isManual) ...[
              const SizedBox(height: 6),
              TextField(
                controller: _manualController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'ID Kurir',
                  hintText: 'Contoh: 3, 10',
                  errorText: _validationError,
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                ),
                onChanged: (_) {
                  if (_validationError != null) {
                    setState(() => _validationError = null);
                  }
                },
              ),
            ],
            if (!_isManual && _validationError != null) ...[
              const SizedBox(height: 6),
              Text(
                _validationError!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: const Text('Tugaskan Kurir'),
        ),
      ],
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
