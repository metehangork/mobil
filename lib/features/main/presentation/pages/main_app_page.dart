import 'package:flutter/material.dart';
import 'chat_view.dart';

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    _HomePage(),
    _MatchesPage(),
    _MessagesPage(),
    _GroupsPage(),
    _ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Eşleşmeler',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Mesajlar',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Gruplar',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniCampus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Bildirimler sayfası
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hoş geldin kartı
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merhaba Ahmet! 👋',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bugün 3 yeni eşleşmen var!\nMesajlaşmaya başlamaya hazır mısın?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Hızlı aksiyonlar
            Text(
              'Hızlı Aksiyonlar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.people_alt,
                    title: 'Yeni Eşleşmeler',
                    subtitle: '3 yeni',
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () {
                      // Tab değiştir
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    context,
                    icon: Icons.chat,
                    title: 'Mesajlar',
                    subtitle: '5 okunmamış',
                    color: Theme.of(context).colorScheme.secondary,
                    onTap: () {
                      // Tab değiştir
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Günün dersleri
            Text(
              'Bugünün Dersleri',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildTodaysClasses(context),
            
            const SizedBox(height: 24),
            
            // Son aktiviteler
            Text(
              'Son Aktiviteler',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildRecentActivities(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysClasses(BuildContext context) {
    final classes = [
      {'name': 'Veri Yapıları', 'time': '09:00', 'room': 'BLG-101'},
      {'name': 'Algoritma Analizi', 'time': '14:00', 'room': 'BLG-205'},
      {'name': 'Veritabanı Sistemleri', 'time': '16:00', 'room': 'BLG-301'},
    ];
    
    return Column(
      children: classes.map((classInfo) => 
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.book,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classInfo['name']!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${classInfo['time']} - ${classInfo['room']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ).toList(),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    final activities = <Map<String, dynamic>>[
      {
        'type': 'match',
        'message': 'Zeynep ile Algoritma dersi için eşleştin',
        'time': '2 saat önce',
        'icon': Icons.people,
      },
      {
        'type': 'message',
        'message': 'Veri Yapıları grubunda yeni mesaj',
        'time': '4 saat önce',
        'icon': Icons.chat,
      },
      {
        'type': 'group',
        'message': 'Matematik çalışma grubuna katıldın',
        'time': '1 gün önce',
        'icon': Icons.groups,
      },
    ];
    
    return Column(
      children: activities.map((activity) => 
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  activity['icon'] as IconData,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['message'] as String,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity['time'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).toList(),
    );
  }
}

// Placeholder sayfalar
class _MatchesPage extends StatelessWidget {
  const _MatchesPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eşleşmeler')),
      body: const Center(
        child: Text('Eşleşmeler sayfası - geliştiriliyor'),
      ),
    );
  }
}

class _MessagesPage extends StatelessWidget {
  const _MessagesPage();

  @override
  Widget build(BuildContext context) {
    final rooms = [
      {'id': 'r1', 'name': 'Matematik 101', 'last': 'Ödev 3 tartışması'},
      {'id': 'r2', 'name': 'Fizik Lab', 'last': 'Rapor paylaşıldı'},
      {'id': 'r3', 'name': 'Sohbet', 'last': 'Selam!'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Mesajlar')),
      body: ListView.separated(
        itemCount: rooms.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final r = rooms[index];
          return ListTile(
            leading: CircleAvatar(child: Text(r['name']![0])),
            title: Text(r['name']!),
            subtitle: Text(r['last']!),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatView(roomId: r['id']!, roomName: r['name']!),
              ));
            },
          );
        },
      ),
    );
  }
}

class _GroupsPage extends StatelessWidget {
  const _GroupsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gruplar')),
      body: const Center(
        child: Text('Gruplar sayfası - geliştiriliyor'),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const Center(
        child: Text('Profil sayfası - geliştiriliyor'),
      ),
    );
  }
}