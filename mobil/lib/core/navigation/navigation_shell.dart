import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../navigation/tab_config.dart';

/// Main navigation shell with bottom navigation bar and nested navigation
class NavigationShell extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onTabChanged;

  const NavigationShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  DateTime? _lastBackPress;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    
    // If last back press was within 2 seconds, exit app
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < TabConfig.doubleTapExitWindow) {
      return true; // Allow exit
    }
    
    // First back press: show toast and record time
    _lastBackPress = now;
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çıkmak için tekrar basın'),
          duration: TabConfig.doubleTapExitWindow,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    return false; // Prevent exit
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: widget.currentIndex,
          onTap: widget.onTabChanged,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: AppTabs.all.map((tab) {
            final isSelected = tab.index == widget.currentIndex;
            return BottomNavigationBarItem(
              icon: Icon(isSelected ? tab.activeIcon : tab.icon),
              label: tab.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}
