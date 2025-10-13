import 'package:flutter/material.dart';

/// Tab configuration and constants
class TabConfig {
  static const int homeIndex = 0;
  static const int coursesIndex = 1;
  static const int groupsIndex = 2;
  static const int messagesIndex = 3;
  static const int profileIndex = 4;
  
  static const int totalTabs = 5;
  
  static const Duration doubleTapExitWindow = Duration(seconds: 2);
}

/// Tab metadata for bottom navigation
class TabItem {
  final int index;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const TabItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

/// All tab definitions
class AppTabs {
  static const home = TabItem(
    index: TabConfig.homeIndex,
    label: 'Ana Sayfa',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    route: 'home',
  );

  static const courses = TabItem(
    index: TabConfig.coursesIndex,
    label: 'Dersler',
    icon: Icons.book_outlined,
    activeIcon: Icons.book,
    route: 'courses',
  );

  static const groups = TabItem(
    index: TabConfig.groupsIndex,
    label: 'Gruplar',
    icon: Icons.group_outlined,
    activeIcon: Icons.group,
    route: 'groups',
  );

  static const messages = TabItem(
    index: TabConfig.messagesIndex,
    label: 'Mesajlar',
    icon: Icons.chat_bubble_outline,
    activeIcon: Icons.chat_bubble,
    route: 'messages',
  );

  static const profile = TabItem(
    index: TabConfig.profileIndex,
    label: 'Profil',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    route: 'profile',
  );

  static const List<TabItem> all = [
    home,
    courses,
    groups,
    messages,
    profile,
  ];
}
