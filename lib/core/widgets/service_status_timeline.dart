import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ServiceStatusTimeline extends StatelessWidget {
  const ServiceStatusTimeline({
    super.key,
    required this.currentStatus,
    this.steps = const ['Menunggu', 'Dikonfirmasi', 'Pengerjaan', 'Selesai'],
  });

  final String currentStatus;
  final List<String> steps;

  int _getCurrentStepIndex() {
    final s = currentStatus.toLowerCase();
    if (s.contains('complete') ||
        s.contains('selesai') ||
        s.contains('paid') ||
        s.contains('verified')) {
      return 3;
    }
    if (s.contains('progress') ||
        s.contains('pengerjaan') ||
        s.contains('working') ||
        s.contains('diagnosed')) {
      return 2;
    }
    if (s.contains('confirm') ||
        s.contains('assigned') ||
        s.contains('dikonfirmasi')) {
      return 1;
    }
    return 0; // pending
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _getCurrentStepIndex();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, size: 16, color: AppColors.secondary),
              const SizedBox(width: 8),
              const Text(
                'Status Pengerjaan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Tahap ${activeIndex + 1} dari ${steps.length}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(steps.length, (index) {
              final isPassed = index <= activeIndex;
              final isCurrent = index == activeIndex;
              final isLast = index == steps.length - 1;

              return Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (index > 0)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: isPassed
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          )
                        else
                          const Spacer(),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? AppColors.primary
                                : isPassed
                                ? AppColors.primaryLight
                                : AppColors.surfaceCardElevated,
                            border: Border.all(
                              color: isPassed
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 2,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryGlow,
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isPassed
                                ? const Icon(
                                    Icons.check,
                                    size: 11,
                                    color: Colors.white,
                                  )
                                : Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.textDisabled,
                                    ),
                                  ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: index < activeIndex
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          )
                        else
                          const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : isPassed
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isCurrent
                            ? AppColors.primaryLight
                            : isPassed
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
