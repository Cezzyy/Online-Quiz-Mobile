import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class AdminCoursesTab extends StatelessWidget {
  const AdminCoursesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.class_outlined,
              size: 80,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            const SizedBox(height: 24),
            Text(
              'Course Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
