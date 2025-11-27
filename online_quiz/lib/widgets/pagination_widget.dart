import 'package:flutter/material.dart';

/// Reusable pagination widget that adapts to light and dark themes
class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final String? previousLabel;
  final String? nextLabel;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.onPreviousPage,
    required this.onNextPage,
    this.previousLabel,
    this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          ElevatedButton.icon(
            onPressed: hasPreviousPage ? onPreviousPage : null,
            icon: const Icon(Icons.chevron_left),
            label: Text(previousLabel ?? 'Previous'),
          ),
          // Page Info
          Text(
            'Page $currentPage of $totalPages',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          // Next Button
          ElevatedButton.icon(
            onPressed: hasNextPage ? onNextPage : null,
            icon: const Icon(Icons.chevron_right),
            label: Text(nextLabel ?? 'Next'),
          ),
        ],
      ),
    );
  }
}
