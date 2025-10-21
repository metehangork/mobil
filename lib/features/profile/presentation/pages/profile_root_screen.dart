import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../../../../core/models/user_model.dart';

/// Profile tab root screen - GERÇEK API ENTEGRASYONU
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

  @override
  void dispose() {
    _overviewScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider(
      create: (_) => ProfileBloc()..add(LoadProfile()),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, profileState) {
          // AuthBloc'dan token kontrolü için
          return BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              final UserModel? authUser =
                  authState is AuthAuthenticated ? authState.user : null;

              return DefaultTabController(
                length: 3,
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(authUser?.name ?? 'Profil'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        tooltip: 'Bildirimler',
                        onPressed: () => context.push('/notifications'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Profili Düzenle',
                        onPressed: () => context.push('/profile/edit'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        tooltip: 'Çıkış Yap',
                        onPressed: () => _showLogoutDialog(context),
                      ),
                    ],
                    bottom: const TabBar(
                      tabs: [
                        Tab(
                          icon: Icon(Icons.person_outline),
                          text: 'Genel Bakış',
                        ),
                        Tab(
                          icon: Icon(Icons.menu_book_outlined),
                          text: 'Derslerim',
                        ),
                        Tab(
                          icon: Icon(Icons.settings_outlined),
                          text: 'Ayarlar',
                        ),
                      ],
                    ),
                  ),
                  body: _buildBody(profileState, authUser),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(ProfileState state, UserModel? authUser) {
    if (state is ProfileLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ProfileError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<ProfileBloc>().add(LoadProfile()),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (state is ProfileLoaded) {
      final profile = state.profile;
      return RefreshIndicator(
        onRefresh: () async {
          context.read<ProfileBloc>().add(LoadProfile());
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: TabBarView(
          children: [
            _buildOverviewTab(profile),
            _buildCoursesTab(profile),
            _buildSettingsTab(profile),
          ],
        ),
      );
    }

    return const Center(child: Text('Profil yükleniyor...'));
  }

  // GENEL BAKIŞ SEKME İÇERİĞİ
  Widget _buildOverviewTab(Map<String, dynamic> profile) {
    return ListView(
      controller: _overviewScrollController,
      padding: const EdgeInsets.all(16.0),
      children: [
        // Profil Kartı
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    (profile['full_name'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 40,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  profile['full_name'] ?? 'Kullanıcı',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  profile['email'] ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                if (profile['bio'] != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    profile['bio'],
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Okul Bilgileri
        Card(
          child: ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Okul'),
            subtitle: Text(profile['school_name'] ?? 'Belirtilmemiş'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Bölüm'),
            subtitle: Text(profile['department_name'] ?? 'Belirtilmemiş'),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.grade),
            title: const Text('Sınıf'),
            subtitle: Text('${profile['study_level'] ?? 1}. Sınıf'),
          ),
        ),

        // İlgi Alanları
        if (profile['interests'] != null &&
            (profile['interests'] as List).isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
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
                    spacing: 8,
                    runSpacing: 8,
                    children: (profile['interests'] as List)
                        .map((interest) => Chip(
                              label: Text(interest.toString()),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],

        // İstatistikler
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.people, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '${profile['total_matches'] ?? 0}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text('Eşleşme'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.group, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '${profile['total_groups'] ?? 0}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text('Grup'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // DERSLER SEKME İÇERİĞİ
  Widget _buildCoursesTab(Map<String, dynamic> profile) {
    final courses = profile['courses'] as List? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Ders ekleme sayfasına git
            context.push('/courses');
          },
          icon: const Icon(Icons.add),
          label: const Text('Ders Ekle'),
        ),
        const SizedBox(height: 16),
        if (courses.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Henüz ders eklemediniz'),
                ],
              ),
            ),
          )
        else
          ...courses.map((course) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(course['code']?[0] ?? 'D'),
                  ),
                  title: Text(course['name'] ?? 'Ders'),
                  subtitle: Text(course['code'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      // Dersi kaldır
                      // TODO: CourseService ile unenroll
                    },
                  ),
                ),
              )),
      ],
    );
  }

  // AYARLAR SEKME İÇERİĞİ
  Widget _buildSettingsTab(Map<String, dynamic> profile) {
    final settings = profile['settings'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Eşleşme İsteklerine İzin Ver'),
                subtitle: const Text(
                    'Diğer öğrenciler size eşleşme isteği gönderebilir'),
                value: settings['allow_match_requests'] ?? true,
                onChanged: (value) {
                  context.read<ProfileBloc>().add(
                        UpdateSettings(allowMatchRequests: value),
                      );
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Çevrimiçi Durumunu Göster'),
                subtitle: const Text(
                    'Diğer kullanıcılar çevrimiçi olduğunuzu görebilir'),
                value: settings['show_online_status'] ?? true,
                onChanged: (value) {
                  context.read<ProfileBloc>().add(
                        UpdateSettings(showOnlineStatus: value),
                      );
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('E-posta Bildirimleri'),
                subtitle: const Text('Önemli güncellemeleri e-posta ile al'),
                value: settings['email_notifications'] ?? true,
                onChanged: (value) {
                  context.read<ProfileBloc>().add(
                        UpdateSettings(emailNotifications: value),
                      );
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Push Bildirimleri'),
                subtitle: const Text('Anlık bildirimler al'),
                value: settings['push_notifications'] ?? true,
                onChanged: (value) {
                  context.read<ProfileBloc>().add(
                        UpdateSettings(pushNotifications: value),
                      );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Gizlilik Politikası'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Gizlilik politikası sayfası
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Kullanım Koşulları'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Kullanım koşulları sayfası
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Hakkında'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Kafadar Kampüs',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2025 Kafadar Kampüs',
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}
