import 'package:flutter/material.dart';

/// Courses tab root screen
class CoursesRootScreen extends StatefulWidget {
  const CoursesRootScreen({super.key});

  @override
  State<CoursesRootScreen> createState() => _CoursesRootScreenState();
}

class _CoursesRootScreenState extends State<CoursesRootScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      debugPrint('🔄 CoursesRootScreen: Refreshed');
      setState(() => _isRefreshing = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dersler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => debugPrint('🔍 Courses: Search tapped'),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => debugPrint('🎯 Courses: Filter tapped'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ders Ekle',
            onPressed: () => debugPrint('➕ Courses: Add course tapped'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(child: _buildEmptyState()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz ders eklemediniz',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Ders ekleyerek ders arkadaşları bulabilirsiniz',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => debugPrint('➕ Add first course'),
              icon: const Icon(Icons.add),
              label: const Text('İlk Dersi Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
