// ignore_for_file: deprecated_member_use

import 'package:bank_app/Pages/prayer_times_page.dart';
import 'package:bank_app/Pages/quran_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Providers/navigation_provider.dart';
import '../utils/responsive_helper.dart';
import 'home_page.dart';
import 'profile_page.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
      page: const HomePage(),
    ),
    NavigationItem(
      icon: Icons.mosque_outlined,
      selectedIcon: Icons.mosque_outlined,
      label: 'Solah Times',
      page: const PrayerTimesPage(),
    ),
    NavigationItem(
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_outlined,
      label: 'Quran',
      page: const QuranPage(),
    ),
    NavigationItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
      page: const ProfilePage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final navigationType = ResponsiveHelper.getNavigationType(context);

    switch (navigationType) {
      case NavigationType.bottom:
        return _buildBottomNavigation(selectedIndex, context);
      case NavigationType.rail:
        return _buildRailNavigation(selectedIndex, context);
      case NavigationType.drawer:
        return _buildDrawerNavigation(selectedIndex, context);
    }
  }

  // ✅ Bottom Navigation using theme colors
  Widget _buildBottomNavigation(int selectedIndex, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _navigationItems[selectedIndex].page,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        backgroundColor: colorScheme.surface,
        showUnselectedLabels: true,
        items: _navigationItems.map((item) {
          final isSelected = _navigationItems.indexOf(item) == selectedIndex;
          return BottomNavigationBarItem(
            icon: Icon(
              isSelected ? item.selectedIcon : item.icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  // ✅ Rail Navigation (tablet/desktop)
  Widget _buildRailNavigation(int selectedIndex, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: _onItemTapped,
            backgroundColor: colorScheme.surface,
            selectedIconTheme: IconThemeData(color: colorScheme.primary),
            unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
            selectedLabelTextStyle: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            labelType: NavigationRailLabelType.all,
            destinations: _navigationItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _navigationItems[selectedIndex].page),
        ],
      ),
    );
  }

  // ✅ Drawer Navigation using theme
  Widget _buildDrawerNavigation(int selectedIndex, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 280,
            color: colorScheme.surface,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  color: colorScheme.primary,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance,
                          color: colorScheme.onPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'SmartOUI Banking',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _navigationItems.length,
                    itemBuilder: (context, index) {
                      final item = _navigationItems[index];
                      final isSelected = selectedIndex == index;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: ListTile(
                          leading: Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: colorScheme.primary.withOpacity(0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () => _onItemTapped(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _navigationItems[selectedIndex].page),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    ref.read(selectedIndexProvider.notifier).setIndex(index);
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
  });
}
