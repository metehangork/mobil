import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  // Mock data - geçici
  static final sampleRooms = [
    {'name': 'Matematik 101', 'lastMessage': 'Ödev 3 hataları tartışıldı.', 'time': '09:12', 'unreadCount': 3},
    {'name': 'Fizik Lab', 'lastMessage': 'Raporlar upload edildi.', 'time': '08:50', 'unreadCount': 0},
    {'name': 'Bilgisayar Müh', 'lastMessage': 'Kod paylaşan var mı?', 'time': 'Dün', 'unreadCount': 7},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniCampus'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Active users / quick actions carousel
            SizedBox(
              height: 96,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: sampleRooms.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final r = sampleRooms[index];
                  return _ActiveRoomChip(roomName: r['name'] as String, unread: r['unreadCount'] as int);
                },
              ),
            ),

            // Pinned / announcements area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: const [
                  Icon(Icons.push_pin, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Ders duyuruları ve sabit mesajlar burada görünür.')),
                ],
              ),
            ),

            // Rooms list
            Expanded(
              child: ListView.separated(
                itemCount: sampleRooms.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final room = sampleRooms[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text((room['name'] as String)[0])),
                    title: Text(room['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(room['lastMessage'] as String, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(room['time'] as String, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        if ((room['unreadCount'] as int) > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                            child: Text('${room['unreadCount']}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          )
                      ],
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Open room: ${room['name']}')),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Sohbet'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Keşfet'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Yeni'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Bildirim'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
        currentIndex: 0,
        onTap: (i) {},
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.edit),
        onPressed: () {},
      ),
    );
  }
}

class _ActiveRoomChip extends StatelessWidget {
  final String roomName;
  final int unread;
  const _ActiveRoomChip({Key? key, required this.roomName, required this.unread}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          child: Text(roomName.isNotEmpty ? roomName[0] : '?'),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  roomName,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (unread > 0)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                  child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11)),
                ),
            ],
          ),
        )
      ],
    );
  }
}
