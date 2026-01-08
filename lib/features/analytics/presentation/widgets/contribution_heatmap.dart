import 'package:flutter/material.dart';

class ContributionHeatmap extends StatelessWidget {
  final Map<DateTime, int> dataset; // Date -> Minutes
  final int daysToLookBack;

  const ContributionHeatmap({
    super.key,
    required this.dataset,
    this.daysToLookBack = 70, // ~10 weeks
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Normalize date to midnight for comparison
    DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

    final normalizedData = dataset.map((k, v) => MapEntry(normalize(k), v));

    // Generate list of days
    final days = List.generate(daysToLookBack, (i) {
      return normalize(now.subtract(Duration(days: (daysToLookBack - 1) - i)));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consistencia',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120, // fixed height for the grid
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  7, // 7 days in a vertical column (Mon-Sun generally)
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final date = days[index];
              final minutes = normalizedData[date] ?? 0;
              return Tooltip(
                message: '${_formatDate(date)}: ${minutes}m',
                child: Container(
                  decoration: BoxDecoration(
                    color: _getColor(
                        minutes, Theme.of(context).colorScheme.primary),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}';
  }

  Color _getColor(int minutes, Color baseColor) {
    if (minutes == 0) return Colors.grey.withValues(alpha: 0.1);
    if (minutes < 15) return baseColor.withValues(alpha: 0.3);
    if (minutes < 45) return baseColor.withValues(alpha: 0.5);
    if (minutes < 90) return baseColor.withValues(alpha: 0.7);
    return baseColor;
  }
}
