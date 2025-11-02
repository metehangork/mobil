import 'package:flutter/material.dart';

/// Groups tab root screen
class GroupsRootScreen extends StatefulWidget {
  const GroupsRootScreen({super.key});

  @override
  State<GroupsRootScreen> createState() => _GroupsRootScreenState();
}

class _GroupsRootScreenState extends State<GroupsRootScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      debugPrint('🔄 GroupsRootScreen: Refreshed');
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
        title: const Text('Gruplar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => debugPrint('🔍 Groups: Search tapped'),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => debugPrint('🎯 Groups: Filter tapped'),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Grup Oluştur',
            onPressed: () => debugPrint('➕ Groups: Create group tapped'),
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
              Icons.group_outlined,
              size: 80,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz grup yok',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Grup oluşturarak veya mevcut gruplara katılarak başlayın',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => debugPrint('➕ Create group'),
                  icon: const Icon(Icons.add),
                  label: const Text('Grup Oluştur'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => debugPrint('🔍 Find groups'),
                  icon: const Icon(Icons.search),
                  label: const Text('Grup Ara'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
