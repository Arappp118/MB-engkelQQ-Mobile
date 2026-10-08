import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
          title: const Text('Assign Courier'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ID Courier',
              hintText: 'Contoh: 5',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            FilledButton(
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
        const SnackBar(content: Text('Courier berhasil ditugaskan.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menugaskan courier.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: Consumer<DeliveryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.deliveryTasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.deliveryTasks.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(provider.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: provider.loadDeliveryTasks,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.deliveryTasks.isEmpty) {
            return RefreshIndicator(
              onRefresh: provider.loadDeliveryTasks,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Belum ada delivery task.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadDeliveryTasks,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.deliveryTasks.length,
              separatorBuilder: (_, _) {
                return const SizedBox(height: 12);
              },
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Delivery Task #${task.id}',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  task.status ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Booking',
              value: task.bookingId?.toString() ?? '-',
            ),
            _InfoRow(label: 'Type', value: task.type ?? '-'),
            _InfoRow(label: 'Pickup', value: task.pickupAddress ?? '-'),
            _InfoRow(
              label: 'Courier',
              value: task.courierId?.toString() ?? 'Belum ditugaskan',
            ),
            if (task.notes != null && task.notes!.trim().isNotEmpty)
              _InfoRow(label: 'Catatan', value: task.notes!),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAssign,
                icon: Icon(assigned ? Icons.edit : Icons.person_add),
                label: Text(assigned ? 'Ganti Courier' : 'Assign Courier'),
              ),
            ),
          ],
        ),
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
            width: 100,
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
