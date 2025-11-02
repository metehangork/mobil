/// API Configuration
class ApiConfig {
  // Base URLs
  // PRODUCTION: Alan adı - kafadarkampus.online
  // NOT: Domain bağlantı sorunu var, geçici olarak direkt IP kullanıyoruz
  static const String baseUrl =
      'http://37.148.210.244:3000'; // Direkt IP kullan
  static const String baseUrlSecure =
      'https://kafadarkampus.online'; // HTTPS (sorunlu)
  static const String baseUrlDev = 'http://37.148.210.244:3000'; // DEV IP
  static const String apiVersion = '/api';

  // Full API URL
  static String get apiUrl => '$baseUrl$apiVersion';

  // Socket.IO URL
  static String get socketUrl => baseUrl;

  // Endpoints
  static const String auth = '/auth';
  static const String users = '/users';
  static const String schools = '/schools';
  static const String departments = '/departments';
  static const String courses = '/courses';
  static const String matches = '/matches';
  static const String groups = '/groups';
  static const String messages = '/messages';
  static const String conversations = '/conversations';
  static const String chats = '/chats'; // Legacy endpoint (eski sistem)
  static const String notifications = '/notifications';

  // Timeouts - Sunucu yavaş olduğu için uzun timeout kullanıyoruz
  static const Duration connectionTimeout = Duration(seconds: 45);
  static const Duration receiveTimeout = Duration(seconds: 45);

  // Headers
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> authHeaders(String token) => {
        ...defaultHeaders,
        'Authorization': 'Bearer $token',
      };
}
