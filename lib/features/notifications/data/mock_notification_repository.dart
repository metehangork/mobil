import 'dart:async';
import '../../../core/models/app_notification.dart';

class MockNotificationRepository {
  Future<List<AppNotification>> fetchNotifications({int limit = 20}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'n1',
        title: 'Acil: Sınav grubu bulundu',
        message: 'CS101 için acil çalışma grubu seni bekliyor.',
        priority: NotificationPriority.critical,
        createdAt: now.subtract(const Duration(minutes: 5)),
        route: '/groups',
      ),
      AppNotification(
        id: 'n2',
        title: 'Önemli: Ortak ders eşleşmesi',
        message: 'MAT201 dersinden 3 yeni eşleşme önerisi var.',
        priority: NotificationPriority.important,
        createdAt: now.subtract(const Duration(hours: 1)),
        route: '/home',
      ),
      AppNotification(
        id: 'n3',
        title: 'Bilgi: Profilini güncelle',
        message: 'Profilini tamamlayarak daha iyi eşleşmeler al.',
        priority: NotificationPriority.normal,
        createdAt: now.subtract(const Duration(days: 1)),
        route: '/profile',
      ),
    ];
  }
}
