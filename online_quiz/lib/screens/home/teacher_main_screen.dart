import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'teacher_home_tab.dart';
import '../courses/teacher_courses_tab.dart';
import '../quizzes/teacher_quiz_tab.dart';
import '../results/teacher_results_tab.dart';
import '../profile/teacher_profile_tab.dart';
import '../notifications/teacher_notification_screen.dart';
import '../../providers/notification_provider.dart';

class TeacherMainScreen extends ConsumerStatefulWidget {
  const TeacherMainScreen({super.key});

  @override
  ConsumerState<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends ConsumerState<TeacherMainScreen> {
  int _currentIndex = 0;

  List<Widget> get _tabs => [
    TeacherHomeTab(onNavigateToTab: _navigateToTab),
    const TeacherCoursesTab(),
    const TeacherQuizTab(),
    const TeacherResultsTab(),
    TeacherProfileTab(onNavigateToTab: _navigateToTab),
  ];

  static const List<String> _tabTitles = [
    'Home',
    'Courses',
    'Quizzes',
    'Results',
    'Profile',
  ];

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6.0),
            child: Image.asset(
              'assets/images/aclclogo-nobg.png',
              fit: BoxFit.contain,
              width: 48,
              height: 48,
            ),
          ),
        ),
        title: Text(
          _tabTitles[_currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TeacherNotificationScreen(),
                    ),
                  );
                },
              ),
              // Show badge for unread notifications
              Consumer(
                builder: (context, ref, child) {
                  final unreadCount = ref.watch(unreadNotificationsProvider).length;
                  if (unreadCount > 0) {
                    return Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Quizzes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Results',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}