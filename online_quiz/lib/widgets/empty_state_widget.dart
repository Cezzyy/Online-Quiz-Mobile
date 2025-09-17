import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;
  final Color? titleColor;
  final Color? messageColor;
  final double iconSize;
  final double titleFontSize;
  final double messageFontSize;
  final EdgeInsetsGeometry padding;
  final bool showInfoCard;
  final String? infoCardText;
  final Color? infoCardColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.subtitle,
    this.action,
    this.iconColor,
    this.titleColor,
    this.messageColor,
    this.iconSize = 80.0,
    this.titleFontSize = 24.0,
    this.messageFontSize = 16.0,
    this.padding = const EdgeInsets.all(32.0),
    this.showInfoCard = false,
    this.infoCardText,
    this.infoCardColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultIconColor = iconColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);
    final defaultTitleColor = titleColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    final defaultMessageColor = messageColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final defaultInfoCardColor = infoCardColor ?? Theme.of(context).colorScheme.primaryContainer;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: defaultIconColor,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: defaultTitleColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: messageFontSize,
                color: defaultMessageColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: messageFontSize,
                  color: defaultMessageColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (showInfoCard && infoCardText != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: defaultInfoCardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (infoCardColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: infoCardColor ?? Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        infoCardText!,
                        style: TextStyle(
                          fontSize: 14,
                          color: (infoCardColor ?? Colors.blue).withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 32),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// Preset configurations for common empty states
class EmptyStatePresets {
  // Notifications empty state
  static EmptyStateWidget notifications() {
    return const EmptyStateWidget(
      icon: Icons.notifications_none,
      title: 'No Notifications',
      message: "You're all caught up!",
      iconColor: Colors.grey,
      titleColor: Colors.grey,
      messageColor: Colors.grey,
    );
  }

  // Courses empty state
  static EmptyStateWidget courses() {
    return EmptyStateWidget(
      icon: Icons.school_outlined,
      title: 'No Enrolled Courses',
      message: 'You have no enrolled courses online.',
      subtitle: 'If you have issues, please contact the school admin.',
      showInfoCard: true,
      infoCardText: 'Contact your administrator to get enrolled in courses.',
      infoCardColor: Colors.blue,
    );
  }

  // Quizzes empty state
  static EmptyStateWidget quizzes() {
    return EmptyStateWidget(
      icon: Icons.quiz_outlined,
      title: 'No Quizzes Available',
      message: 'You have no quizzes assigned at the moment.',
      subtitle: 'Check back later for new quizzes from your courses.',
      showInfoCard: true,
      infoCardText: 'New quizzes will appear here when assigned by your instructors.',
      infoCardColor: Colors.blue,
    );
  }

  // Quiz results empty state
  static EmptyStateWidget quizResults() {
    return const EmptyStateWidget(
      icon: Icons.quiz_outlined,
      title: 'No quiz results found',
      message: 'Complete some quizzes to see your results here',
      iconColor: Colors.grey,
      titleColor: Colors.grey,
      messageFontSize: 14,
      titleFontSize: 18,
    );
  }

  // Search results empty state
  static EmptyStateWidget searchResults(String query) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'No Results Found',
      message: 'No results found for "$query"',
      subtitle: 'Try adjusting your search terms or filters.',
      iconSize: 64,
      titleFontSize: 20,
      messageFontSize: 14,
    );
  }

  // Generic empty state with custom action
  static EmptyStateWidget withAction({
    required IconData icon,
    required String title,
    required String message,
    required Widget action,
    String? subtitle,
    Color? primaryColor,
  }) {
    return EmptyStateWidget(
      icon: icon,
      title: title,
      message: message,
      subtitle: subtitle,
      action: action,
      iconColor: primaryColor?.withValues(alpha: 0.6),
      titleColor: primaryColor?.withValues(alpha: 0.8),
      messageColor: primaryColor?.withValues(alpha: 0.7),
    );
  }

  // Loading state (can be used as empty state while loading)
  static EmptyStateWidget loading({
    String title = 'Loading...',
    String message = 'Please wait while we fetch your data.',
  }) {
    return EmptyStateWidget(
      icon: Icons.hourglass_empty,
      title: title,
      message: message,
      iconColor: Colors.blue.shade300,
      titleColor: Colors.blue.shade700,
      messageColor: Colors.blue.shade600,
      action: const CircularProgressIndicator(),
    );
  }

  // Error state
  static EmptyStateWidget error({
    String title = 'Something went wrong',
    String message = 'We encountered an error while loading your data.',
    VoidCallback? onRetry,
  }) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: title,
      message: message,
      subtitle: 'Please try again or contact support if the problem persists.',
      iconColor: Colors.red.shade300,
      titleColor: Colors.red.shade700,
      messageColor: Colors.red.shade600,
      action: onRetry != null
          ? ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
            )
          : null,
    );
  }

  // Network error state
  static EmptyStateWidget networkError({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.wifi_off,
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      iconColor: Colors.orange.shade300,
      titleColor: Colors.orange.shade700,
      messageColor: Colors.orange.shade600,
      action: onRetry != null
          ? ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
              ),
            )
          : null,
    );
  }
}