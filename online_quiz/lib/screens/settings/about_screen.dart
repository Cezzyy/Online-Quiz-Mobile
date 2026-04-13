import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/aclclogo-nobg.png',
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 24),

            // App Name
            Text(
              'ACLC Online Quiz',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Description
            _buildSection(
              context,
              icon: Icons.info_outline,
              title: 'About the App',
              content:
                  'ACLC Online Quiz is a comprehensive mobile application designed to enhance the learning experience for students and simplify quiz management for instructors at ACLC.',
            ),

            const SizedBox(height: 20),

            // For Students
            _buildSection(
              context,
              icon: Icons.school,
              title: 'For Students',
              content:
                  'Take quizzes anytime, anywhere. Track your progress across all courses, view detailed results and analytics, receive notifications for upcoming quizzes, and monitor your academic performance with comprehensive statistics.',
            ),

            const SizedBox(height: 20),

            // For Instructors
            _buildSection(
              context,
              icon: Icons.person_outline,
              title: 'For Instructors',
              content:
                  'Create and manage quizzes efficiently. Monitor student performance, track quiz completion rates, manage course content, and access detailed analytics to improve teaching effectiveness.',
            ),

            const SizedBox(height: 20),

            // Key Features
            _buildSection(
              context,
              icon: Icons.star_outline,
              title: 'Key Features',
              content: '',
              children: [
                _buildFeatureItem(context, 'Course Management', 'Browse and access all your enrolled courses'),
                _buildFeatureItem(context, 'Quiz System', 'Take quizzes with time limits and instant feedback'),
                _buildFeatureItem(context, 'Results Tracking', 'View detailed performance analytics and history'),
                _buildFeatureItem(context, 'Notifications', 'Stay updated with quiz deadlines and announcements'),
                _buildFeatureItem(context, 'Profile Management', 'Customize your profile and preferences'),
                _buildFeatureItem(context, 'Dark Mode', 'Comfortable viewing in any lighting condition'),
              ],
            ),
            const SizedBox(height: 32),

            // Footer
            Text(
              '© 2026 ACLC College of Mandaue',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    List<Widget>? children,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ],
          if (children != null) ...[
            const SizedBox(height: 12),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String title, String description) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
