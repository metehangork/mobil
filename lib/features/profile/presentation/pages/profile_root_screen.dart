import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../../core/models/user_model.dart'; // UserModel'i import et

/// Profile tab root screen
class ProfileRootScreen extends StatefulWidget {
  const ProfileRootScreen({super.key});

  @override
  State<ProfileRootScreen> createState() => _ProfileRootScreenState();
}

class _ProfileRootScreenState extends State<ProfileRootScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _overviewScrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  Future<void> _onRefresh() async {
    // TODO: Gerçek bir refresh logic'i ekle (örn: AuthBloc'a event göndermek)
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      debugPrint('🔄 ProfileRootScreen: Refreshed');
    }
  }

  @override
  void dispose() {
    _overviewScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // AuthState'den kullanıcıyı al
        final UserModel? user =
            state is AuthAuthenticated ? state.user : null;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(user?.name ?? 'Profil'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Bildirimler',
                  onPressed: () {
                    context.push('/notifications');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Profili Düzenle',
                  onPressed: () {
                    context.push('/profile/edit');
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Çıkış Yap',
                  onPressed: () => _showLogoutDialog(context),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.person_outline), text: 'Genel Bakış'),
                  Tab(icon: Icon(Icons.menu_book_outlined), text: 'Derslerim'),
                  Tab(icon: Icon(Icons.settings_outlined), text: 'Ayarlar'),
                ],
              ),
            ),
            body: user == null
                ? const Center(child: Text('Kullanıcı bulunamadı.'))
                : TabBarView(
                    children: [
                      _buildOverviewTab(user),
                      _buildCoursesTab(user),
                      _buildSettingsTab(),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // GENEL BAKIŞ SEKME İÇERİĞİ
  Widget _buildOverviewTab(UserModel user) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        controller: _overviewScrollController,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildProfileHeader(user),
          const SizedBox(height: 24),
          _buildBioCard(user),
          const SizedBox(height: 16),
          _buildHobbiesCard(user),
          const SizedBox(height: 16),
          _buildStatsCard(user),
        ],
      ),
    );
  }

  // DERSLERİM SEKME İÇERİĞİ
  Widget _buildCoursesTab(UserModel user) {
    final courses = user.courses;
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Derslerim (${courses.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Ders ekleme düzenleme akışı
                        debugPrint('➕ Ders ekle');
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Ders Ekle',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (courses.isEmpty)
                  Text(
                    'Henüz ders eklenmemiş. Profilini tamamlamak için derslerini ekle.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: courses
                        .map(
                          (c) => Chip(
                            label: Text(c),
                            avatar: const Icon(Icons.book_outlined, size: 16),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // AYARLAR SEKME İÇERİĞİ
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSettingsSection(),
      ],
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          // TODO: Gerçek avatarUrl'i kullan
          backgroundImage:
              user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          child: user.avatarUrl == null
              ? Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          '${user.university} - ${user.department}',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBioCard(UserModel user) {
    if (user.bio == null || user.bio!.isEmpty) {
      return const SizedBox.shrink(); // Bio yoksa gösterme
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hakkımda',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              user.bio!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHobbiesCard(UserModel user) {
    if (user.hobbies.isEmpty) {
      return const SizedBox.shrink(); // Hobi yoksa gösterme
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'İlgi Alanları',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: user.hobbies
                  .map((hobby) => Chip(
                        label: Text(hobby),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withOpacity(0.5),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(user.courses.length.toString(), 'Derslerim'),
            _buildStatItem(user.stats.completedGroups.toString(), 'Gruplarım'),
            _buildStatItem(
                '${user.stats.matchSuccessRate.toStringAsFixed(0)}%', 'Başarı'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Column(
        children: [
          _buildMenuItem(Icons.notifications_outlined, 'Bildirimler'),
          _buildMenuItem(Icons.lock_outline, 'Gizlilik ve Güvenlik'),
          _buildMenuItem(Icons.help_outline, 'Yardım & Destek'),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: onTap ?? () => debugPrint('👆 Profile: $title tapped'),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}
