import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../models/delivery_task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/delivery_provider.dart';
import '../../services/location_service.dart';
import '../../core/constants/workshop_constants.dart';
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
        SnackBar(content: Text('Gagal memuat pickup task: $error')),
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
          title: const Text('Logout'),
          content: const Text('Apakah kamu yakin ingin logout?'),
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

    if (shouldLogout != true || !mounted) {
      return;
    }

    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: _isLoading
            ? ListView(
                children: const [
                  SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              )
            : Consumer<DeliveryProvider>(
                builder: (context, provider, child) {
                  final tasks = provider.deliveryTasks;

                  if (tasks.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(
                          height: 300,
                          child: Center(child: Text('Belum ada pickup task.')),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];

                      return _DeliveryTaskCard(
                        task: task,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  CourierTaskDetailPage(taskId: task.id),
                            ),
                          );
                        },
                      );
                    },
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================================================
            // HEADER TASK
            // =========================================================
            Row(
              children: [
                const Icon(Icons.local_shipping, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pickup Task #${task.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDFC7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // =========================================================
            // BOOKING
            // =========================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 72,
                  child: Text(
                    'Booking',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(child: Text('${task.bookingId ?? '-'}')),
              ],
            ),

            const SizedBox(height: 10),

            // =========================================================
            // TYPE
            // =========================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 72,
                  child: Text(
                    'Type',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(child: Text(task.type ?? '-')),
              ],
            ),

            const SizedBox(height: 10),

            // =========================================================
            // PICKUP
            // =========================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 72,
                  child: Text(
                    'Pickup',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: Text(
                    task.pickupAddress != null &&
                            task.pickupAddress!.trim().isNotEmpty
                        ? task.pickupAddress!
                        : '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // =========================================================
            // BUTTON LIHAT DETAIL
            // =========================================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Lihat Detail'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A5C0F),
                  foregroundColor: Colors.white,
                  elevation: 0,
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
        SnackBar(content: Text('Gagal memuat detail pickup: $error')),
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pickup berhasil dimulai.')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memulai pickup: $error')));
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
        const SnackBar(content: Text('Pickup berhasil diselesaikan.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyelesaikan pickup: $error')),
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
        const SnackBar(content: Text('Lokasi Courier berhasil didapatkan.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
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
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pickup')),
      body: Consumer<DeliveryProvider>(
        builder: (context, provider, child) {
          final task = provider.selectedDeliveryTask;

          if (_isLoading && task == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (task == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Data pickup tidak ditemukan.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadTask,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final status = task.status ?? '';

          final canStart = status == 'assigned';

          final canComplete =
              status == 'in_progress' ||
              status == 'picked_up' ||
              status == 'pickup_started';

          return RefreshIndicator(
            onRefresh: _loadTask,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // =====================================================
                // DETAIL PICKUP
                // =====================================================
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup #${task.id}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Booking ID: '
                          '${task.bookingId ?? '-'}',
                        ),

                        Text(
                          'Status: '
                          '${task.status ?? '-'}',
                        ),

                        Text(
                          'Tipe: '
                          '${task.type ?? '-'}',
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'Alamat Pickup',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),

                        const SizedBox(height: 4),

                        Text(
                          task.pickupAddress ??
                              'Alamat pickup '
                                  'belum tersedia.',
                        ),

                        if (task.notes != null && task.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Catatan',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(task.notes!),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =====================================================
                // LOKASI COURIER
                // =====================================================
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Lokasi Courier',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),

                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          onPressed: _isLocationLoading
                              ? null
                              : _getCourierLocation,
                          icon: _isLocationLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(
                            _isLocationLoading
                                ? 'Mengambil Lokasi...'
                                : 'Ambil Lokasi Saya',
                          ),
                        ),

                        if (_courierPosition != null) ...[
                          const SizedBox(height: 16),

                          Text(
                            'Latitude: '
                            '${_courierPosition!.latitude}',
                          ),

                          Text(
                            'Longitude: '
                            '${_courierPosition!.longitude}',
                          ),

                          if (_courierAddress != null &&
                              _courierAddress!.isNotEmpty)
                            Text(
                              'Alamat: '
                              '$_courierAddress',
                            ),
                        ],

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _openMapForTask(task),
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Buka di Maps'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _launchNavigationForTask(task),
                                icon: const Icon(Icons.navigation_outlined),
                                label: const Text('Navigasi'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =====================================================
                // STATUS COMPLETED
                // =====================================================
                if (status == 'completed')
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              'Pickup telah selesai.',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // =====================================================
                // MULAI PICKUP
                // =====================================================
                if (canStart)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _startPickup,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Mulai Pickup'),
                    ),
                  ),

                // =====================================================
                // SELESAIKAN PICKUP
                // =====================================================
                if (canComplete)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _completePickup,
                      icon: const Icon(Icons.check),
                      label: const Text('Selesaikan Pickup'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
