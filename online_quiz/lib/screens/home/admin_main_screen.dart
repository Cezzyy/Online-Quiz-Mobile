import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_home_tab.dart';
import '../admin/admin_users_tab.dart';
import '../admin/admin_courses_tab.dart';
import '../admin/admin_notifications_tab.dart';
import '../admin/admin_settings_tab.dart';
import '../../providers/notification_provider.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  int _currentIndex = 0;

  List<Widget> get _tabs => [
    const AdminHomeTab(),
    const AdminUsersTab(),
    const AdminCoursesTab(),
    const AdminNotificationsTab(),
    const AdminSettingsTab(),
  ];

  static const List<String> _tabTitles = [
    'Home',
    'Users',
    'Courses',
    'Notifications',
    'Settings',
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
                  // Navigate to notifications tab
                  _navigateToTab(3);
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
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
