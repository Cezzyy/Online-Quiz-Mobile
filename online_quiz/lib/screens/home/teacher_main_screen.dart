import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'teacher_home_tab.dart';
import '../courses/teacher_courses_tab.dart';
import '../quiz/teacher_quiz_tab.dart';
import '../results/teacher_results_tab.dart';
import '../profile/teacher_profile_tab.dart';
import '../../providers/auth_provider.dart';

class TeacherMainScreen extends ConsumerStatefulWidget {
  const TeacherMainScreen({super.key});

  @override
  ConsumerState<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends ConsumerState<TeacherMainScreen> {
  int _currentIndex = 0;

  static final List<Widget> _tabs = [
    const TeacherHomeTab(),
    const TeacherCoursesTab(),
    const TeacherQuizTab(),
    const TeacherResultsTab(),
    const TeacherProfileTab(),
  ];

  static const List<String> _tabTitles = [
    'Home',
    'Courses',
    'Quizzes',
    'Results',
    'Profile',
  ];

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
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              // Perform logout - AuthWrapper will handle navigation automatically
              await ref.read(authProvider.notifier).logout();
            },
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