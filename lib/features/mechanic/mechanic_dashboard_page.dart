import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/service_item.dart';
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

  Future<void> _showServiceItemPicker() async {
    final provider = context.read<ServiceOrderProvider>();
    await provider.loadServiceItems();

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _ServiceItemCatalogSheet(
          serviceOrderId: widget.serviceOrderId,
          onItemAdded: () async {
            Navigator.of(sheetContext).pop();
            await _loadServiceOrder();
          },
        );
      },
    );
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
                      if (!isCompleted) ...[
                        const SizedBox(height: 14),
                        SecondaryButton(
                          text: 'Pilih Jasa / Sparepart dari Katalog',
                          icon: Icons.add_circle_outline,
                          onPressed: _showServiceItemPicker,
                          height: 44,
                        ),
                      ],
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

// ============================================================
// SERVICE ITEM CATALOG BOTTOM SHEET
// ============================================================

class _ServiceItemCatalogSheet extends StatefulWidget {
  const _ServiceItemCatalogSheet({
    required this.serviceOrderId,
    required this.onItemAdded,
  });

  final int serviceOrderId;
  final VoidCallback onItemAdded;

  @override
  State<_ServiceItemCatalogSheet> createState() =>
      _ServiceItemCatalogSheetState();
}

class _ServiceItemCatalogSheetState extends State<_ServiceItemCatalogSheet> {
  String _searchQuery = '';
  String _categoryFilter = 'all'; // 'all', 'service', 'sparepart'
  ServiceItem? _selectedItem;
  int _quantity = 1;
  bool _isSubmitting = false;

  String _formatMoney(double value) {
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

  Future<void> _submitAddItem() async {
    final item = _selectedItem;
    if (item == null) return;

    setState(() => _isSubmitting = true);
    final provider = context.read<ServiceOrderProvider>();

    final success = await provider.addServiceOrderItem(
      orderId: widget.serviceOrderId,
      serviceItemId: item.id,
      quantity: _quantity,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} berhasil ditambahkan ke service order.'),
          backgroundColor: AppColors.success,
        ),
      );
      widget.onItemAdded();
    } else {
      final err = provider.errorMessage ?? 'Gagal menambahkan item.';
      final statusCode = provider.errorStatusCode;
      final is404 = statusCode == 404;
      final is422 = statusCode == 422;
      final is403 = statusCode == 403;
      final is401 = statusCode == 401;

      String dialogTitle = 'Gagal Menambahkan Item';
      IconData dialogIcon = Icons.warning_amber_rounded;
      Color dialogColor = AppColors.warning;

      if (is404) {
        dialogTitle = 'Endpoint API Belum Tersedia';
        dialogIcon = Icons.cloud_off_rounded;
        dialogColor = AppColors.error;
      } else if (is422) {
        dialogTitle = 'Validasi / Stok Tidak Cukup';
        dialogIcon = Icons.inventory_2_outlined;
        dialogColor = AppColors.warning;
      } else if (is403) {
        dialogTitle = 'Akses Ditolak';
        dialogIcon = Icons.lock_outline_rounded;
        dialogColor = AppColors.error;
      } else if (is401) {
        dialogTitle = 'Sesi Berakhir';
        dialogIcon = Icons.login_rounded;
        dialogColor = AppColors.warning;
      }

      showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Row(
            children: [
              Icon(dialogIcon, color: dialogColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dialogTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (is404) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'HTTP 404: $err',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Data pesanan servis atau endpoint tidak ditemukan di server (HTTP 404: $err).\n\n'
                        'Pastikan backend Laravel versi terbaru sudah aktif dengan rute "POST /api/v1/service-orders/{id}/items" dan ID pesanan servis valid.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Katalog jasa/sparepart di bawah tetap aktif untuk melihat daftar referensi item.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ] else if (is422) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Permintaan ditolak oleh server (HTTP 422):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        err,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pastikan stok mencukupi atau kurangi kuantitas yang diminta.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ] else if (is403) ...[
                Text(
                  'Akses Ditolak (HTTP 403):\n$err\n\nHanya mekanik yang ditugaskan pada order ini atau admin yang diizinkan menambahkan item.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ] else if (is401) ...[
                const Text(
                  'Sesi autentikasi Anda telah berakhir (HTTP 401). Silakan login kembali.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ] else ...[
                Text(
                  'Respons server:\n$err',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Consumer<ServiceOrderProvider>(
        builder: (context, provider, child) {
          final items = provider.serviceItems;
          final isLoading = provider.isLoadingItems;
          final error = provider.errorMessageItems;

          final filteredItems = items.where((item) {
            final matchesQuery = _searchQuery.isEmpty ||
                item.name.toLowerCase().contains(_searchQuery.toLowerCase());
            if (!matchesQuery) return false;

            if (_categoryFilter == 'sparepart') {
              return item.isSparepart;
            } else if (_categoryFilter == 'service') {
              return !item.isSparepart;
            }
            return true;
          }).toList();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Katalog Jasa & Sparepart',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Pilih item dari data master backend Laravel',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cari jasa atau sparepart...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Semua'),
                      selected: _categoryFilter == 'all',
                      onSelected: (selected) {
                        if (selected) setState(() => _categoryFilter = 'all');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Jasa'),
                      selected: _categoryFilter == 'service',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _categoryFilter = 'service');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Sparepart'),
                      selected: _categoryFilter == 'sparepart',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _categoryFilter = 'sparepart');
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Items List
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (isLoading && items.isEmpty) {
                      return const Center(
                        child: LoadingState(
                          message: 'Memuat katalog backend...',
                        ),
                      );
                    }
                    if (error != null && items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                error,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SecondaryButton(
                                text: 'Muat Ulang',
                                onPressed: () => provider.loadServiceItems(),
                                width: 130,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (filteredItems.isEmpty) {
                      return const Center(
                        child: Text(
                          'Tidak ada item yang sesuai.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filteredItems.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isSelected = _selectedItem?.id == item.id;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedItem = item;
                              _quantity = 1;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryContainer.withValues(
                                      alpha: 0.4,
                                    )
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: item.isSparepart
                                        ? AppColors.secondaryContainer
                                        : AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    item.isSparepart
                                        ? Icons.settings_outlined
                                        : Icons.build_outlined,
                                    size: 20,
                                    color: item.isSparepart
                                        ? AppColors.secondary
                                        : AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatMoney(item.price),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      if (item.isSparepart && item.stock != null)
                                        Text(
                                          (item.stock ?? 0) <= 0
                                              ? 'Stok: 0 (Habis)'
                                              : 'Stok: ${item.stock}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: (item.stock ?? 0) <= 0
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: (item.stock ?? 0) > 0
                                                ? AppColors.textSecondary
                                                : AppColors.error,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                  size: 22,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Selected item action bar
              if (_selectedItem != null) ...[
                const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Builder(
                    builder: (context) {
                      final item = _selectedItem!;
                      final isSparepart = item.isSparepart;
                      final stock = item.stock ?? 0;
                      final isOutOfStock = isSparepart && item.stock != null && stock <= 0;
                      final maxQty = (isSparepart && item.stock != null) ? stock : 999;
                      final canIncrease = _quantity < maxQty;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal (${_quantity}x):',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                _formatMoney(item.price * _quantity),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Quantity selector
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: (!isOutOfStock && _quantity > 1)
                                          ? () => setState(() => _quantity--)
                                          : null,
                                    ),
                                    Text(
                                      '$_quantity',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isOutOfStock
                                            ? AppColors.error
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: (!isOutOfStock && canIncrease)
                                          ? () => setState(() => _quantity++)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PrimaryButton(
                                  text: isOutOfStock
                                      ? 'Stok Habis'
                                      : 'Tambahkan ke Order',
                                  isLoading: _isSubmitting,
                                  onPressed: (_isSubmitting || isOutOfStock)
                                      ? null
                                      : _submitAddItem,
                                  height: 46,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
