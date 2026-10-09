import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/workshop_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/delivery_task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../services/location_service.dart';
import '../maps/interactive_map_page.dart';

class CourierDashboardPage extends StatefulWidget {
  const CourierDashboardPage({super.key});

  @override
  State<CourierDashboardPage> createState() => _CourierDashboardPageState();
}

class _CourierDashboardPageState extends State<CourierDashboardPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  Future<void> _loadTasks() async {
    final provider = context.read<DeliveryProvider>();

    setState(() {
      _isLoading = true;
    });

    try {
      await provider.loadDeliveryTasks();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat pickup task: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
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
            'Apakah kamu yakin ingin logout?',
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

    if (shouldLogout != true || !mounted) {
      return;
    }

    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Courier Dashboard'),
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
              context.push('/maps');
              break;
            case 2:
              context.push('/notifications');
              break;
            case 3:
              _logout();
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping, color: AppColors.primary),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: AppColors.primary),
            label: 'Peta',
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
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        color: AppColors.primary,
        child: _isLoading
            ? const LoadingState(message: 'Memuat tugas kurir...')
            : Consumer<DeliveryProvider>(
                builder: (context, provider, child) {
                  final tasks = provider.deliveryTasks;

                  if (tasks.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        EmptyState(
                          icon: Icons.local_shipping_outlined,
                          title: 'Belum Ada Tugas',
                          message: 'Belum ada pickup task yang ditugaskan kepada Anda.',
                        ),
                      ],
                    );
                  }

                  final assignedTasks = tasks
                      .where((t) => t.status == 'assigned')
                      .length;
                  final activeTasks = tasks
                      .where(
                        (t) =>
                            t.status == 'in_progress' ||
                            t.status == 'picked_up' ||
                            t.status == 'pickup_started',
                      )
                      .length;
                  final completedTasks = tasks
                      .where((t) => t.status == 'completed')
                      .length;

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: [
                      // Stat overview
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Menunggu',
                              value: '$assignedTasks',
                              icon: Icons.access_time,
                              accentColor: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              title: 'Aktif',
                              value: '$activeTasks',
                              icon: Icons.near_me_outlined,
                              accentColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              title: 'Selesai',
                              value: '$completedTasks',
                              icon: Icons.check_circle_outline,
                              accentColor: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Daftar Tugas Pengantaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...tasks.map((task) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DeliveryTaskCard(
                            task: task,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CourierTaskDetailPage(taskId: task.id),
                                ),
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class _DeliveryTaskCard extends StatelessWidget {
  const _DeliveryTaskCard({required this.task, required this.onTap});

  final DeliveryTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = task.status ?? '-';

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
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  size: 22,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pickup Task #${task.id}',
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
          _InfoRow(label: 'Booking', value: '${task.bookingId ?? '-'}'),
          _InfoRow(label: 'Tipe', value: task.type ?? '-'),
          _InfoRow(
            label: 'Pickup',
            value:
                task.pickupAddress != null &&
                    task.pickupAddress!.trim().isNotEmpty
                ? task.pickupAddress!
                : '-',
          ),
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
            width: 76,
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

class CourierTaskDetailPage extends StatefulWidget {
  const CourierTaskDetailPage({required this.taskId, super.key});

  final int taskId;

  @override
  State<CourierTaskDetailPage> createState() => _CourierTaskDetailPageState();
}

class _CourierTaskDetailPageState extends State<CourierTaskDetailPage> {
  bool _isLoading = false;
  bool _isLocationLoading = false;

  final LocationService _locationService = LocationService();

  Position? _courierPosition;
  String? _courierAddress;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTask();
    });
  }

  Future<void> _loadTask() async {
    final provider = context.read<DeliveryProvider>();

    setState(() {
      _isLoading = true;
    });

    try {
      await provider.loadDeliveryTask(widget.taskId);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat detail pickup: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startPickup() async {
    final provider = context.read<DeliveryProvider>();

    setState(() {
      _isLoading = true;
    });

    try {
      await provider.startDeliveryTask(widget.taskId);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup berhasil dimulai.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memulai pickup: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completePickup() async {
    final provider = context.read<DeliveryProvider>();

    setState(() {
      _isLoading = true;
    });

    try {
      await provider.completeDeliveryTask(widget.taskId);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pickup berhasil diselesaikan.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyelesaikan pickup: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCourierLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      final position = await _locationService.getCurrentPosition();

      final address = await _locationService.getAddressFromPosition(position);

      if (!mounted) {
        return;
      }

      setState(() {
        _courierPosition = position;
        _courierAddress = address;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi Courier berhasil didapatkan.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  Future<void> _openMapForTask(DeliveryTask task) async {
    double destLat = WorkshopConstants.workshopLatitude;
    double destLng = WorkshopConstants.workshopLongitude;

    if (task.pickupAddress != null && task.pickupAddress!.trim().isNotEmpty) {
      try {
        final pos = await _locationService.getCoordinatesFromAddress(
          task.pickupAddress!,
        );
        if (pos != null) {
          destLat = pos.latitude;
          destLng = pos.longitude;
        }
      } catch (_) {}
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InteractiveMapPage(
          mode: MapPageMode.viewer,
          destinationLatitude: destLat,
          destinationLongitude: destLng,
          destinationTitle: 'Pickup #${task.id}',
          destinationAddress:
              task.pickupAddress ?? WorkshopConstants.workshopAddress,
        ),
      ),
    );
  }

  Future<void> _launchNavigationForTask(DeliveryTask task) async {
    double destLat = WorkshopConstants.workshopLatitude;
    double destLng = WorkshopConstants.workshopLongitude;

    if (task.pickupAddress != null && task.pickupAddress!.trim().isNotEmpty) {
      try {
        final pos = await _locationService.getCoordinatesFromAddress(
          task.pickupAddress!,
        );
        if (pos != null) {
          destLat = pos.latitude;
          destLng = pos.longitude;
        }
      } catch (_) {}
    }

    final launched = await _locationService.launchNavigation(
      destLat,
      destLng,
      destinationTitle: 'Pickup #${task.id}',
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka aplikasi navigasi/peta.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Pickup')),
      body: Consumer<DeliveryProvider>(
        builder: (context, provider, child) {
          final task = provider.selectedDeliveryTask;

          if (_isLoading && task == null) {
            return const LoadingState(message: 'Memuat data pickup...');
          }

          if (task == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Data pickup tidak ditemukan.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      text: 'Coba Lagi',
                      onPressed: _loadTask,
                      width: 140,
                    ),
                  ],
                ),
              ),
            );
          }

          final status = task.status ?? '';

          final canStart = status == 'assigned';
          final canComplete =
              status == 'in_progress' ||
              status == 'picked_up' ||
              status == 'pickup_started';
          final isCompleted = status == 'completed';

          return RefreshIndicator(
            onRefresh: _loadTask,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // =====================================================
                // DETAIL PICKUP
                // =====================================================
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
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              size: 22,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pickup #${task.id}',
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
                      _DetailItem(
                        label: 'Booking ID',
                        value: '${task.bookingId ?? '-'}',
                      ),
                      _DetailItem(
                        label: 'Tipe Layanan',
                        value: task.type ?? '-',
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Alamat Pickup',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
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
                              Icons.location_on_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.pickupAddress ??
                                    'Alamat pickup belum tersedia.',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (task.notes != null && task.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Catatan:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task.notes!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // =====================================================
                // LOKASI COURIER
                // =====================================================
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              Icons.my_location,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Lokasi Courier',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _isLocationLoading
                            ? null
                            : _getCourierLocation,
                        icon: _isLocationLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              )
                            : const Icon(Icons.my_location, size: 18),
                        label: Text(
                          _isLocationLoading
                              ? 'Mengambil Lokasi...'
                              : 'Ambil Lokasi Saya',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_courierPosition != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lat: ${_courierPosition!.latitude.toStringAsFixed(6)}, Lng: ${_courierPosition!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              if (_courierAddress != null &&
                                  _courierAddress!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _courierAddress!,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () => _openMapForTask(task),
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: const Text(
                                'Buka di Maps',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.secondary,
                                side: const BorderSide(
                                  color: AppColors.secondary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: () => _launchNavigationForTask(task),
                              icon: const Icon(
                                Icons.navigation_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Navigasi',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // =====================================================
                // STATUS COMPLETED
                // =====================================================
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
                            'Pickup telah selesai.',
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

                // =====================================================
                // MULAI PICKUP
                // =====================================================
                if (canStart)
                  PrimaryButton(
                    text: 'Mulai Pickup',
                    icon: Icons.play_arrow,
                    isLoading: _isLoading,
                    onPressed: _startPickup,
                    height: 48,
                  ),

                // =====================================================
                // SELESAIKAN PICKUP
                // =====================================================
                if (canComplete)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _completePickup,
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text(
                        'Selesaikan Pickup',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
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
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
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
