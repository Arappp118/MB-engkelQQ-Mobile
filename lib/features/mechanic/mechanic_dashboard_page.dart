import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah Anda yakin ingin logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
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
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Consumer<ServiceOrderProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.serviceOrders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.serviceOrders.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadServiceOrders,
              child: ListView(
                children: [
                  const SizedBox(height: 220),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, size: 56),
                          const SizedBox(height: 16),
                          const Text(
                            'Gagal memuat Service Order',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadServiceOrders,
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.serviceOrders.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadServiceOrders,
              child: ListView(
                children: const [
                  SizedBox(height: 250),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.build_circle_outlined, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'Belum ada Service Order',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Service Order yang ditugaskan kepada mechanic akan muncul di sini.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadServiceOrders,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.serviceOrders.length,
              itemBuilder: (context, index) {
                final order = provider.serviceOrders[index];

                return _ServiceOrderCard(
                  order: order,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MechanicServiceDetailPage(serviceOrderId: order.id),
                      ),
                    );

                    if (mounted) {
                      await _loadServiceOrders();
                    }
                  },
                );
              },
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDFC7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.build, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Service Order #${order.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),

            const SizedBox(height: 18),

            _InfoRow(label: 'Booking', value: '${order.bookingId ?? '-'}'),

            const SizedBox(height: 8),

            _InfoRow(label: 'Customer', value: '${order.customerId ?? '-'}'),

            const SizedBox(height: 8),

            _InfoRow(label: 'Mechanic', value: '${order.mechanicId ?? '-'}'),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Lihat Detail'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A5C0F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ],
        ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

// ============================================================
// STATUS BADGE
// ============================================================

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDFC7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        const SnackBar(content: Text('Service berhasil dimulai.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal memulai service.'),
        ),
      );
    }
  }

  Future<void> _saveDiagnosis() async {
    final diagnosis = _diagnosisController.text.trim();

    if (diagnosis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnosis tidak boleh kosong.')),
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
        const SnackBar(content: Text('Diagnosis berhasil disimpan.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menyimpan diagnosis.'),
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

    // --------------------------------------------------------
    // CEK DIAGNOSIS
    // --------------------------------------------------------

    final hasDiagnosis =
        order.diagnosis != null && order.diagnosis!.trim().isNotEmpty;

    if (!hasDiagnosis) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Diagnosis mekanik harus diisi sebelum menyelesaikan service.',
          ),
        ),
      );
      return;
    }

    // --------------------------------------------------------
    // CEK SERVICE ITEM
    // --------------------------------------------------------

    if (order.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada tindakan/service item pada Service Order ini. Service belum dapat diselesaikan melalui aplikasi mobile.',
          ),
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
        const SnackBar(content: Text('Service berhasil diselesaikan.')),
      );
    } else {
      final error = provider.errorMessage ?? 'Gagal menyelesaikan service.';

      // ------------------------------------------------------
      // HANDLE BR-012 SECARA RAMAH
      // ------------------------------------------------------

      if (error.toLowerCase().contains('br-012')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Service belum dapat diselesaikan karena diagnosis atau service item belum lengkap.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Service')),
      body: Consumer<ServiceOrderProvider>(
        builder: (context, provider, child) {
          final order = provider.selectedServiceOrder;

          if (provider.isLoading && order == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (order == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Service Order tidak ditemukan.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadServiceOrder,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final status = order.status ?? '';

          // Backend saat ini menggunakan
          // status "in_progress".
          //
          // "in_service" tetap diterima
          // sebagai kompatibilitas jika
          // ada data lama.

          final isAssigned = status == 'assigned';

          final isInProgress =
              status == 'in_progress' || status == 'in_service';

          final isCompleted = status == 'completed';

          final hasDiagnosis =
              order.diagnosis != null && order.diagnosis!.trim().isNotEmpty;

          final hasServiceItems = order.items.isNotEmpty;

          final canStart = isAssigned;

          final canComplete = isInProgress && hasDiagnosis && hasServiceItems;

          return RefreshIndicator(
            onRefresh: _loadServiceOrder,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ==================================================
                // DETAIL SERVICE ORDER
                // ==================================================

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDFC7),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.build, size: 30),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Service Order #${order.id}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

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

                        _DetailRow(label: 'Status', value: order.status ?? '-'),

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
                        ),

                        if (order.notes != null &&
                            order.notes!.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Catatan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(order.notes!),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // SERVICE ITEM / TINDAKAN SERVICE
                // ==================================================
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.handyman_outlined),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Tindakan Service',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${order.items.length} item',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (order.items.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber, color: Colors.orange),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Belum ada service item/tindakan service pada Service Order ini. Selesaikan Service belum dapat dilakukan.',
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
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F8F8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      color: Color(0xFF9A5C0F),
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
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Qty: ${item.quantity}'),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Harga: ${_formatMoney(item.price)}',
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Subtotal: ${_formatMoney(item.subtotal)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
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
                ),

                const SizedBox(height: 16),

                // ==================================================
                // DIAGNOSIS
                // ==================================================
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Diagnosis',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextField(
                          controller: _diagnosisController,
                          minLines: 4,
                          maxLines: 7,
                          decoration: InputDecoration(
                            hintText: 'Masukkan hasil diagnosis...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: provider.isLoading
                                ? null
                                : _saveDiagnosis,
                            icon: const Icon(Icons.save),
                            label: const Text('Simpan Diagnosis'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // INFORMASI SEBELUM COMPLETE
                // ==================================================
                if (isInProgress &&
                    !isCompleted &&
                    (!hasDiagnosis || !hasServiceItems))
                  Card(
                    color: Colors.orange.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                'Belum dapat diselesaikan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (!hasDiagnosis)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Text('• Diagnosis mekanik belum diisi.'),
                            ),

                          if (!hasServiceItems)
                            const Text(
                              '• Belum ada service item/tindakan service.',
                            ),
                        ],
                      ),
                    ),
                  ),

                // ==================================================
                // MULAI SERVICE
                // ==================================================
                if (canStart)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _startService,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Mulai Service'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9A5C0F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),

                // ==================================================
                // SELESAIKAN SERVICE
                // ==================================================
                if (isInProgress)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading || !canComplete
                          ? null
                          : _completeService,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Selesaikan Service'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),

                // ==================================================
                // COMPLETED
                // ==================================================
                if (isCompleted)
                  Card(
                    margin: const EdgeInsets.only(top: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 30,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Service telah selesai.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
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

    return 'Rp ${value.toStringAsFixed(0)}';
  }
}

// ============================================================
// DETAIL ROW
// ============================================================

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
