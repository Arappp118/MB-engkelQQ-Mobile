import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.customLabel});

  final String status;
  final String? customLabel;

  static Color getStatusColor(String rawStatus) {
    final s = rawStatus.toLowerCase();
    if (s.contains('verified') ||
        s.contains('selesai') ||
        s.contains('completed') ||
        s.contains('paid') ||
        s.contains('success') ||
        s.contains('active')) {
      return AppColors.success;
    }
    if (s.contains('pending') ||
        s.contains('menunggu') ||
        s.contains('waiting') ||
        s.contains('draft')) {
      return AppColors.warning;
    }
    if (s.contains('cancel') ||
        s.contains('batal') ||
        s.contains('reject') ||
        s.contains('tolak') ||
        s.contains('failed')) {
      return AppColors.error;
    }
    // Default cyan for in-progress, confirmed, assigned, on the way, etc.
    return AppColors.secondary;
  }

  static String formatStatusLabel(String rawStatus) {
    return rawStatus
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final color = getStatusColor(status);
    final label = customLabel ?? formatStatusLabel(status);

    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
