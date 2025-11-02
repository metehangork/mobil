import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _fcmToken;

  Future<void> initialize() async {
    // Request permission for iOS
    await _firebaseMessaging.requestPermission();

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    // print('FCM Token: $_fcmToken');
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  String? get fcmToken => _fcmToken;

  void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    _localNotifications.show(
      0,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? '',
      details,
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // print('Handling background message: ${message.messageId}');
}
