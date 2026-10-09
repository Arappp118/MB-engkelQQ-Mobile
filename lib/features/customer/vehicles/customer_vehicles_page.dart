import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/premium_card.dart';
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
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Hapus Kendaraan',
      content:
          'Yakin ingin menghapus kendaraan ${vehicle.nomorPolisi} dari daftar akun Anda?',
      confirmText: 'Hapus',
      isDestructive: true,
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
        const SnackBar(
          content: Text('Kendaraan berhasil dihapus.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Kendaraan gagal dihapus.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VehicleProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kendaraan Saya'),
        backgroundColor: AppColors.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: provider.isLoading ? null : _openAddVehicle,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Kendaraan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceCard,
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
          LoadingState(height: 350, message: 'Memuat data kendaraan...'),
        ],
      );
    }

    if (provider.errorMessage != null && provider.vehicles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 60),
          ErrorState(
            title: 'Kendaraan Gagal Dimuat',
            message: provider.errorMessage!,
            onRetry: provider.isLoading ? null : _refresh,
          ),
        ],
      );
    }

    if (provider.vehicles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 60),
          EmptyState(
            icon: Icons.two_wheeler_outlined,
            title: 'Belum Ada Kendaraan',
            message: 'Tambahkan motor Anda untuk memudahkan proses booking servis secara rutin.',
            actionLabel: 'Tambah Sekarang',
            onAction: _openAddVehicle,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: provider.vehicles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
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

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.two_wheeler,
                  size: 26,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDarker,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        vehicle.nomorPolisi,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                iconColor: AppColors.textSecondary,
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                        SizedBox(width: 10),
                        Text('Edit Kendaraan'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 10),
                        Text('Hapus Kendaraan'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (vehicle.tahun != null ||
              vehicle.warna != null ||
              vehicle.tipeMesin != null) ...[
            const SizedBox(height: 14),
            const Divider(color: AppColors.borderSubtle),
            const SizedBox(height: 10),
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
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
