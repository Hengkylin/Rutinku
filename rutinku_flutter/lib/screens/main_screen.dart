import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'calendar_screen.dart';
import 'dashboard_screen.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    final screens = [
      const DashboardScreen(),
      const CalendarScreen(),
      const Center(
        child: Text(
          'Halaman Statistik/Profil (Segera Hadir)',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Kalender',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Milikku',
          ),
        ],
      ),
    );
  }
}
