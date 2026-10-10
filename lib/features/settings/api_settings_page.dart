import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/premium_card.dart';

class ApiSettingsPage extends StatefulWidget {
  const ApiSettingsPage({super.key});

  @override
  State<ApiSettingsPage> createState() => _ApiSettingsPageState();
}

class _ApiSettingsPageState extends State<ApiSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _urlController;

  bool _isTesting = false;
  bool _isSaving = false;
  ConnectionTestResult? _testResult;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConfig.instance.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _runConnectionTest() async {
    final rawUrl = _urlController.text.trim();
    if (rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan URL server sebelum melakukan tes koneksi.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String normalized;
    try {
      normalized = ApiConfig.normalizeUrl(rawUrl);
      _urlController.text = normalized;
    } catch (e) {
      setState(() {
        _testResult = ConnectionTestResult.failure(
          message: e is FormatException ? e.message : 'Format URL tidak valid.',
        );
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final result = await ApiConfig.instance.testConnection(normalized);

    if (!mounted) return;

    setState(() {
      _isTesting = false;
      _testResult = result;
    });
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final rawUrl = _urlController.text.trim();
    String normalized;
    try {
      normalized = ApiConfig.normalizeUrl(rawUrl);
      _urlController.text = normalized;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is FormatException ? e.message : 'Format URL tidak valid.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final currentUrl = ApiConfig.instance.baseUrl;

    if (normalized != currentUrl) {
      final confirmed = await ConfirmationDialog.show(
        context,
        title: 'Konfirmasi Perubahan URL',
        content:
            'URL aktif akan diubah dari:\n$currentUrl\n\nMenjadi:\n$normalized\n\nSemua request API berikutnya akan diarahkan ke server ini. Lanjutkan?',
        confirmText: 'Ganti URL',
        cancelText: 'Batal',
      );

      if (confirmed != true) return;
    }

    setState(() => _isSaving = true);

    try {
      await ApiConfig.instance.setBaseUrl(normalized);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfigurasi URL server berhasil disimpan.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan URL: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _resetDefault() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Reset ke Default?',
      content:
          'URL akan dikembalikan ke URL emulator default:\n${ApiConfig.defaultBaseUrl}',
      confirmText: 'Reset',
      cancelText: 'Batal',
    );

    if (confirmed != true) return;

    await ApiConfig.instance.resetToDefault();
    _urlController.text = ApiConfig.defaultBaseUrl;

    if (!mounted) return;

    setState(() {
      _testResult = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL berhasil direset ke konfigurasi default emulator.'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _applyPreset(String presetUrl) {
    setState(() {
      _urlController.text = presetUrl;
      _testResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentBaseUrl = ApiConfig.instance.baseUrl;
    final isDefault = ApiConfig.instance.isDefault;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Pengaturan Server API',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset Default',
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: _resetDefault,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Active Server Info Card
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.dns_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'URL Aktif Saat Ini',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDefault
                                  ? AppColors.infoContainer
                                  : AppColors.successContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isDefault ? 'EMULATOR DEFAULT' : 'CUSTOM SERVER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDefault
                                    ? AppColors.info
                                    : AppColors.success,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundDarker,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                currentBaseUrl,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: AppColors.secondaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              color: AppColors.textSecondary,
                              tooltip: 'Salin URL',
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: currentBaseUrl),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('URL disalin ke clipboard.'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Form Edit Card
                PremiumCard(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Ubah Alamat Server',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Gunakan alamat IP lokal laptop saat testing di HP fisik Android, atau domain HTTPS saat backend sudah di-hosting.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _urlController,
                          keyboardType: TextInputType.url,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Base URL API',
                            hintText: 'http://192.168.1.19:8000/api/v1',
                            prefixIcon: Icon(Icons.link_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'URL API tidak boleh kosong.';
                            }
                            try {
                              ApiConfig.normalizeUrl(value);
                              return null;
                            } catch (e) {
                              return e is FormatException
                                  ? e.message
                                  : 'Format URL tidak valid.';
                            }
                          },
                        ),

                        const SizedBox(height: 14),

                        // Presets
                        const Text(
                          'Preset Cepat:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPresetChip(
                              'Emulator (10.0.2.2)',
                              'http://10.0.2.2:8000/api/v1',
                            ),
                            _buildPresetChip(
                              'Contoh LAN HP',
                              'http://192.168.1.19:8000/api/v1',
                            ),
                            _buildPresetChip(
                              'Localhost (127.0.0.1)',
                              'http://127.0.0.1:8000/api/v1',
                            ),
                            _buildPresetChip(
                              'Domain HTTPS',
                              'https://domain-hosting.example/api/v1',
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: SecondaryButton(
                                text: _isTesting ? 'Menguji...' : 'Tes Koneksi',
                                icon: Icons.network_check_rounded,
                                isLoading: _isTesting,
                                onPressed: _isTesting
                                    ? null
                                    : _runConnectionTest,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: PrimaryButton(
                                text: _isSaving ? 'Menyimpan...' : 'Simpan URL',
                                icon: Icons.save_rounded,
                                isLoading: _isSaving,
                                onPressed: _isSaving ? null : _saveConfig,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Test Status Section
                if (_testResult != null) ...[
                  _buildStatusCard(_testResult!),
                  const SizedBox(height: 20),
                ],

                // Troubleshooting Guide Card
                PremiumCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Panduan Testing di HP Android Fisik',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildGuideStep(
                        '1',
                        'Jalankan server Laravel di laptop dengan perintah:',
                        code: 'php artisan serve --host=0.0.0.0 --port=8000',
                      ),
                      _buildGuideStep(
                        '2',
                        'Pastikan HP dan laptop terhubung ke jaringan Wi-Fi yang sama.',
                      ),
                      _buildGuideStep(
                        '3',
                        'Cari tahu alamat IP LAN laptop saat ini (gunakan terminal `ip a` atau `ipconfig`), misalnya 192.168.1.19.',
                      ),
                      _buildGuideStep(
                        '4',
                        'Masukkan URL format: http://IP-LAN-LAPTOP:8000/api/v1 lalu klik "Tes Koneksi" & "Simpan URL".',
                      ),
                      _buildGuideStep(
                        '5',
                        'Jika nanti backend di-hosting ke cloud, masukkan domain HTTPS: https://domain-hosting.example/api/v1.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String url) {
    final isSelected = _urlController.text.trim() == url;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _applyPreset(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? AppColors.primaryLight
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ConnectionTestResult result) {
    final isSuccess = result.isSuccess;
    final color = isSuccess ? AppColors.success : AppColors.error;
    final containerColor = isSuccess
        ? AppColors.successContainer
        : AppColors.errorContainer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSuccess ? 'Koneksi Berhasil!' : 'Koneksi Gagal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              if (result.latency != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${result.latency!.inMilliseconds} ms',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            result.message,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String text, {String? code}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                if (code != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDarker,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: SelectableText(
                      code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
