import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/service_order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_order_provider.dart';

class MechanicDashboardPage extends StatefulWidget {
  const MechanicDashboardPage({super.key});

  @override
  State<MechanicDashboardPage> createState() => _MechanicDashboardPageState();
}

class _MechanicDashboardPageState extends State<MechanicDashboardPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServiceOrders();
    });
  }

  Future<void> _loadServiceOrders() async {
    final provider = context.read<ServiceOrderProvider>();

    final success = await provider.loadServiceOrders();

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal memuat service order.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'Apakah Anda yakin ingin logout?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await context.read<AuthProvider>().logout();

    if (!mounted) {
      return;
    }

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mechanic Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              context.push('/notifications');
            },
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppColors.error),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.push('/notifications');
              break;
            case 2:
              _logout();
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build, color: AppColors.primary),
            label: 'Pekerjaan',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: AppColors.primary),
            label: 'Notifikasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Akun',
          ),
        ],
      ),
      body: Consumer<ServiceOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.serviceOrders.isEmpty) {
            return const LoadingState(message: 'Memuat data pekerjaan...');
          }

          if (provider.errorMessage != null && provider.serviceOrders.isEmpty) {
            return ErrorState(
              title: 'Gagal memuat Service Order',
              message: provider.errorMessage!,
              onRetry: _loadServiceOrders,
            );
          }

          if (provider.serviceOrders.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadServiceOrders,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.build_circle_outlined,
                    title: 'Belum ada Service Order',
                    message: 'Service Order yang ditugaskan kepada mechanic akan muncul di sini.',
                  ),
                ],
              ),
            );
          }

          final orders = provider.serviceOrders;
          final inProgressCount = orders
              .where(
                (o) => o.status == 'in_progress' || o.status == 'in_service',
              )
              .length;
          final assignedCount = orders
              .where((o) => o.status == 'assigned' || o.status == 'pending')
              .length;
          final completedCount = orders
              .where((o) => o.status == 'completed' || o.status == 'paid')
              .length;

          return RefreshIndicator(
            onRefresh: _loadServiceOrders,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Quick Summary Header
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Antrean',
                        value: '$assignedCount',
                        icon: Icons.assignment_outlined,
                        accentColor: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        title: 'Dikerjakan',
                        value: '$inProgressCount',
                        icon: Icons.timelapse,
                        accentColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        title: 'Selesai',
                        value: '$completedCount',
                        icon: Icons.check_circle_outline,
                        accentColor: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Daftar Pekerjaan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...orders.map((order) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ServiceOrderCard(
                      order: order,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MechanicServiceDetailPage(
                              serviceOrderId: order.id,
                            ),
                          ),
                        );

                        if (mounted) {
                          await _loadServiceOrders();
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// SERVICE ORDER CARD
// ============================================================

class _ServiceOrderCard extends StatelessWidget {
  const _ServiceOrderCard({required this.order, required this.onTap});

  final ServiceOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = order.status ?? '-';

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.build_rounded,
                  size: 22,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Service Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _InfoRow(label: 'Booking', value: '${order.bookingId ?? '-'}'),
          _InfoRow(label: 'Customer', value: '${order.customerId ?? '-'}'),
          _InfoRow(label: 'Mechanic', value: '${order.mechanicId ?? '-'}'),
          if (order.diagnosis != null && order.diagnosis!.trim().isNotEmpty)
            _InfoRow(label: 'Diagnosis', value: order.diagnosis!),
          const SizedBox(height: 14),
          PrimaryButton(
            text: 'Lihat Detail',
            icon: Icons.arrow_forward,
            onPressed: onTap,
            height: 44,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INFO ROW
// ============================================================

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
            width: 86,
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

// ============================================================
// DETAIL SERVICE ORDER
// ============================================================

class MechanicServiceDetailPage extends StatefulWidget {
  const MechanicServiceDetailPage({required this.serviceOrderId, super.key});

  final int serviceOrderId;

  @override
  State<MechanicServiceDetailPage> createState() =>
      _MechanicServiceDetailPageState();
}

class _MechanicServiceDetailPageState extends State<MechanicServiceDetailPage> {
  final TextEditingController _diagnosisController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServiceOrder();
    });
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    super.dispose();
  }

  Future<void> _loadServiceOrder() async {
    final provider = context.read<ServiceOrderProvider>();

    final success = await provider.loadServiceOrder(widget.serviceOrderId);

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal memuat detail Service Order.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final order = provider.selectedServiceOrder;

    if (order != null &&
        order.diagnosis != null &&
        order.diagnosis!.trim().isNotEmpty) {
      _diagnosisController.text = order.diagnosis!;
    }
  }

  Future<void> _startService() async {
    final provider = context.read<ServiceOrderProvider>();

    final success = await provider.startServiceOrder(widget.serviceOrderId);

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service berhasil dimulai.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal memulai service.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _saveDiagnosis() async {
    final diagnosis = _diagnosisController.text.trim();

    if (diagnosis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagnosis tidak boleh kosong.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final provider = context.read<ServiceOrderProvider>();

    final success = await provider.submitDiagnosis(
      id: widget.serviceOrderId,
      diagnosis: diagnosis,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagnosis berhasil disimpan.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menyimpan diagnosis.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _completeService() async {
    final provider = context.read<ServiceOrderProvider>();

    final order = provider.selectedServiceOrder;

    if (order == null) {
      return;
    }

    final hasDiagnosis =
        order.diagnosis != null && order.diagnosis!.trim().isNotEmpty;

    if (!hasDiagnosis) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Diagnosis mekanik harus diisi sebelum menyelesaikan service.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (order.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada tindakan/service item pada Service Order ini. Service belum dapat diselesaikan melalui aplikasi mobile.',
          ),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final success = await provider.completeServiceOrder(widget.serviceOrderId);

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service berhasil diselesaikan.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final error = provider.errorMessage ?? 'Gagal menyelesaikan service.';

      if (error.toLowerCase().contains('br-012')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Service belum dapat diselesaikan karena diagnosis atau service item belum lengkap.',
            ),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Service')),
      body: Consumer<ServiceOrderProvider>(
        builder: (context, provider, child) {
          final order = provider.selectedServiceOrder;

          if (provider.isLoading && order == null) {
            return const LoadingState(
              message: 'Memuat detail service order...',
            );
          }

          if (order == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Service Order tidak ditemukan.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: 'Coba Lagi',
                      onPressed: _loadServiceOrder,
                      width: 140,
                    ),
                  ],
                ),
              ),
            );
          }

          final status = order.status ?? '';

          final isPending = status == 'pending';
          final isAssigned = status == 'assigned';
          final isInProgress =
              status == 'in_progress' || status == 'in_service';
          final isCompleted = status == 'completed';

          final hasDiagnosis =
              order.diagnosis != null && order.diagnosis!.trim().isNotEmpty;
          final hasServiceItems = order.items.isNotEmpty;

          // Sesuai kontrak backend (ServiceOrderService::startService),
          // order hanya dapat dimulai dari status 'pending'.
          // Status 'assigned' tidak otomatis dapat dimulai via endpoint start.
          final canStart = isPending;
          final canComplete = isInProgress && hasDiagnosis && hasServiceItems;

          return RefreshIndicator(
            onRefresh: _loadServiceOrder,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ==================================================
                // DETAIL SERVICE ORDER
                // ==================================================
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.build_rounded,
                              size: 22,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Service Order #${order.id}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          StatusBadge(status: status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 14),
                      _DetailRow(
                        label: 'Booking ID',
                        value: '${order.bookingId ?? '-'}',
                      ),
                      _DetailRow(
                        label: 'Customer ID',
                        value: '${order.customerId ?? '-'}',
                      ),
                      _DetailRow(
                        label: 'Mechanic ID',
                        value: '${order.mechanicId ?? '-'}',
                      ),
                      _DetailRow(
                        label: 'Subtotal',
                        value: _formatMoney(order.subtotal),
                      ),
                      _DetailRow(
                        label: 'Delivery Fee',
                        value: _formatMoney(order.deliveryFee),
                      ),
                      _DetailRow(
                        label: 'Grand Total',
                        value: _formatMoney(order.grandTotal),
                        isBold: true,
                      ),
                      if (order.notes != null &&
                          order.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Catatan:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.notes!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // SERVICE ITEM / TINDAKAN SERVICE
                // ==================================================
                PremiumCard(
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
                              Icons.handyman_outlined,
                              size: 18,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Tindakan Service',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '${order.items.length} item',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 12),
                      if (order.items.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warningContainer,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Belum ada service item/tindakan service pada Service Order ini. Selesaikan Service belum dapat dilakukan.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: order.items.map((item) {
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.secondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Qty: ${item.quantity} × ${_formatMoney(item.price)}',
                                              style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              _formatMoney(item.subtotal),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                                fontSize: 13,
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
                          }).toList(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // DIAGNOSIS
                // ==================================================
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.assignment_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Diagnosis Mekanik',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _diagnosisController,
                        minLines: 3,
                        maxLines: 6,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Masukkan hasil diagnosis teknis...',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                          ),
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      PrimaryButton(
                        text: 'Simpan Diagnosis',
                        icon: Icons.save_outlined,
                        isLoading: provider.isLoading,
                        onPressed: _saveDiagnosis,
                        height: 44,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // INFORMASI SEBELUM COMPLETE
                // ==================================================
                if (isInProgress &&
                    !isCompleted &&
                    (!hasDiagnosis || !hasServiceItems))
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warningContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Belum dapat diselesaikan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (!hasDiagnosis)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• Diagnosis mekanik belum diisi.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        if (!hasServiceItems)
                          const Text(
                            '• Belum ada service item/tindakan service.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),

                // ==================================================
                // NOTICE STATUS ASSIGNED (TIDAK OTOMATIS DAPAT DIMULAI)
                // ==================================================
                if (isAssigned)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.infoContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Status service order adalah assigned. Berdasarkan aturan server, endpoint mulai servis hanya dapat diproses dari status pending.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ==================================================
                // MULAI SERVICE
                // ==================================================
                if (canStart)
                  PrimaryButton(
                    text: 'Mulai Service',
                    icon: Icons.play_arrow,
                    isLoading: provider.isLoading,
                    onPressed: _startService,
                    height: 48,
                  ),

                // ==================================================
                // SELESAIKAN SERVICE
                // ==================================================
                if (isInProgress)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: canComplete
                            ? AppColors.success
                            : AppColors.surface,
                        foregroundColor: canComplete
                            ? Colors.white
                            : AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: canComplete
                                ? AppColors.success
                                : AppColors.border,
                          ),
                        ),
                      ),
                      onPressed: provider.isLoading || !canComplete
                          ? null
                          : _completeService,
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: const Text(
                        'Selesaikan Service',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                // ==================================================
                // COMPLETED
                // ==================================================
                if (isCompleted)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.successContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 26,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Service telah selesai.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatMoney(double? value) {
    if (value == null) {
      return '-';
    }

    final rounded = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(rounded[i]);
    }
    return 'Rp ${buffer.toString()}';
  }
}

// ============================================================
// DETAIL ROW
// ============================================================

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? AppColors.primary : AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
