import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/vehicle.dart';
import '../../../providers/vehicle_provider.dart';
import 'vehicle_form_page.dart';

class CustomerVehiclesPage extends StatefulWidget {
  const CustomerVehiclesPage({super.key});

  @override
  State<CustomerVehiclesPage> createState() => _CustomerVehiclesPageState();
}

class _CustomerVehiclesPageState extends State<CustomerVehiclesPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().loadVehicles();
    });
  }

  Future<void> _refresh() async {
    await context.read<VehicleProvider>().loadVehicles();
  }

  Future<void> _openAddVehicle() async {
    final result = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const VehicleFormPage()));

    if (result == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _openEditVehicle(Vehicle vehicle) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VehicleFormPage(vehicle: vehicle)),
    );

    if (result == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Kendaraan'),
          content: Text(
            'Yakin ingin menghapus kendaraan '
            '${vehicle.nomorPolisi}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<VehicleProvider>();

    final success = await provider.deleteVehicle(vehicle.id);

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendaraan berhasil dihapus.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Kendaraan gagal dihapus.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VehicleProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Kendaraan Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isLoading ? null : _openAddVehicle,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(context, provider),
      ),
    );
  }

  Widget _buildBody(BuildContext context, VehicleProvider provider) {
    if (provider.isLoading && provider.vehicles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (provider.errorMessage != null && provider.vehicles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.cloud_off_outlined, size: 64),
          const SizedBox(height: 16),
          Text(
            'Kendaraan tidak dapat dimuat',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(provider.errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: provider.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      );
    }

    if (provider.vehicles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.two_wheeler_outlined, size: 72),
          const SizedBox(height: 20),
          Text(
            'Belum Ada Kendaraan',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan kendaraan untuk mulai '
            'membuat booking service.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openAddVehicle,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Kendaraan'),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: provider.vehicles.length,
      separatorBuilder: (_, _) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final vehicle = provider.vehicles[index];

        return _VehicleCard(
          vehicle: vehicle,
          onEdit: () => _openEditVehicle(vehicle),
          onDelete: () => _deleteVehicle(vehicle),
        );
      },
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final vehicleName = [
      vehicle.merk,
      vehicle.model,
    ].where((value) => value.isNotEmpty).join(' ');

    final subtitle = vehicleName.isEmpty ? 'Data kendaraan' : vehicleName;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  child: Icon(Icons.two_wheeler, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.nomorPolisi,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) {
                    return const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline),
                          title: Text('Hapus'),
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            if (vehicle.tahun != null ||
                vehicle.warna != null ||
                vehicle.tipeMesin != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (vehicle.tahun != null)
                    Expanded(
                      child: _VehicleInfo(
                        icon: Icons.calendar_today_outlined,
                        label: 'Tahun',
                        value: vehicle.tahun.toString(),
                      ),
                    ),
                  if (vehicle.warna != null)
                    Expanded(
                      child: _VehicleInfo(
                        icon: Icons.palette_outlined,
                        label: 'Warna',
                        value: vehicle.warna!,
                      ),
                    ),
                  if (vehicle.tipeMesin != null)
                    Expanded(
                      child: _VehicleInfo(
                        icon: Icons.settings_outlined,
                        label: 'Mesin',
                        value: vehicle.tipeMesin!,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VehicleInfo extends StatelessWidget {
  const _VehicleInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
