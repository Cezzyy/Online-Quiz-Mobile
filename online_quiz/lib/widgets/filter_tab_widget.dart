import 'package:flutter/material.dart';

class FilterTabWidget extends StatelessWidget {
  final List<String> options;
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final bool isScrollable;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final double borderRadius;
  final bool showBorder;
  final Color? borderColor;

  const FilterTabWidget({
    super.key,
    required this.options,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.isScrollable = false,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.transparent,
    this.selectedTextColor = Colors.white,
    this.unselectedTextColor = Colors.grey,
    this.borderRadius = 16.0,
    this.showBorder = true,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderColor = borderColor ?? Theme.of(context).colorScheme.outline;
    final defaultUnselectedColor = unselectedColor == Colors.transparent
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
        : unselectedColor;
    
    Widget tabRow = Row(
      children: options.map((filter) {
        final isSelected = selectedFilter == filter;
        final isExpanded = !isScrollable;
        
        Widget tabWidget = GestureDetector(
          onTap: () => onFilterChanged(filter),
          child: Container(
            margin: isScrollable 
                ? const EdgeInsets.only(right: 10)
                : const EdgeInsets.symmetric(horizontal: 4),
            padding: isScrollable
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
                : const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? selectedColor : defaultUnselectedColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: showBorder
                  ? Border.all(
                      color: isSelected ? selectedColor : defaultBorderColor,
                    )
                  : null,
            ),
            child: Text(
              filter,
              textAlign: isScrollable ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                color: isSelected ? selectedTextColor : unselectedTextColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
        
        return isExpanded ? Expanded(child: tabWidget) : tabWidget;
      }).toList(),
    );

    if (isScrollable) {
      tabRow = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: tabRow,
      );
    }

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 20),
      padding: padding,
      color: backgroundColor,
      child: tabRow,
    );
  }
}

// Preset configurations for common use cases
class FilterTabPresets {
  // Quiz tab style (expanded tabs with rounded corners)
  static FilterTabWidget quizStyle({
    required List<String> options,
    required String selectedFilter,
    required Function(String) onFilterChanged,
    required BuildContext context,
  }) {
    return FilterTabWidget(
      options: options,
      selectedFilter: selectedFilter,
      onFilterChanged: onFilterChanged,
      isScrollable: false,
      borderRadius: 25.0,
      showBorder: false,
      unselectedColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
    );
  }

  // Results tab style (scrollable tabs with borders)
  static FilterTabWidget resultsStyle({
    required List<String> options,
    required String selectedFilter,
    required Function(String) onFilterChanged,
    required BuildContext context,
  }) {
    return FilterTabWidget(
      options: options,
      selectedFilter: selectedFilter,
      onFilterChanged: onFilterChanged,
      isScrollable: false,
      borderRadius: 16.0,
      showBorder: true,
      unselectedColor: Colors.transparent,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  // Custom minimal style
  static FilterTabWidget minimal({
    required List<String> options,
    required String selectedFilter,
    required Function(String) onFilterChanged,
    Color selectedColor = Colors.blue,
  }) {
    return FilterTabWidget(
      options: options,
      selectedFilter: selectedFilter,
      onFilterChanged: onFilterChanged,
      isScrollable: false,
      borderRadius: 8.0,
      showBorder: false,
      selectedColor: selectedColor,
      unselectedColor: selectedColor.withValues(alpha: 0.1),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}