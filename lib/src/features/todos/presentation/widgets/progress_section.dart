import 'package:flutter/material.dart';

class ProgressSection extends StatelessWidget {
  const ProgressSection({
    super.key,
    required this.completedCount,
    required this.totalCount,
    required this.progress,
    required this.primaryColor,
  });

  final int completedCount;
  final int totalCount;
  final double progress;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progress',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _ProgressChartCard(
          completedCount: completedCount,
          totalCount: totalCount,
          progress: progress,
          primaryColor: primaryColor,
        ),
      ],
    );
  }
}

class _ProgressChartCard extends StatelessWidget {
  const _ProgressChartCard({
    required this.completedCount,
    required this.totalCount,
    required this.progress,
    required this.primaryColor,
  });

  final int completedCount;
  final int totalCount;
  final double progress;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final pendingCount = (totalCount - completedCount).clamp(0, totalCount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0, 1),
                  backgroundColor: Colors.white70,
                  strokeWidth: 9,
                  color: primaryColor,
                ),
                Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Progress',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _ProgressMetric(label: 'Total tasks', value: '$totalCount'),
                _ProgressMetric(
                  label: 'Completed',
                  value: '$completedCount',
                  accent: const Color(0xFF2E8B57),
                ),
                _ProgressMetric(
                  label: 'Pending',
                  value: '$pendingCount',
                  accent: const Color(0xFFCC4B37),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.label,
    required this.value,
    this.accent = const Color(0xFF2F3348),
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
