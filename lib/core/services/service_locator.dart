import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'user_service.dart';
import 'school_service.dart';
// import 'department_service.dart'; // Bu servis henüz oluşturulmamış
import 'course_service.dart';
import 'match_service.dart';
import 'group_service.dart';
import 'notification_service.dart';
import 'message_service.dart';

/// Service Locator - Dependency injection for all services
/// 
/// Usage:
/// ```dart
/// // Initialize once at app startup
/// await ServiceLocator.initialize();
/// 
/// // Access services anywhere
/// final authService = ServiceLocator.get<AuthService>();
/// final userService = ServiceLocator.get<UserService>();
/// ```
class ServiceLocator {
  static final Map<Type, dynamic> _services = {};
  static bool _isInitialized = false;

  /// Initialize all services
  /// Call this once in main.dart before running the app
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _services[SharedPreferences] = prefs;

    // Create ApiClient
    final apiClient = ApiClient();
    _services[ApiClient] = apiClient;

    // Initialize all services with shared ApiClient
    _services[AuthService] = AuthService(apiClient, prefs);
    _services[UserService] = UserService(apiClient);
    _services[SchoolService] = SchoolService(apiClient);
    // _services[DepartmentService] = DepartmentService(apiClient); // Bu servis henüz oluşturulmamış
    _services[CourseService] = CourseService(apiClient);
    _services[MatchService] = MatchService(apiClient);
    _services[GroupService] = GroupService(apiClient);
    _services[NotificationService] = NotificationService(apiClient);
    _services[MessageService] = MessageService(apiClient);

    // Load saved token if exists
    final authService = _services[AuthService] as AuthService;
    final token = await authService.getToken();
    if (token != null) {
      apiClient.setToken(token);
    }

    _isInitialized = true;
  }

  /// Get service instance by type
  static T get<T>() {
    if (!_isInitialized) {
      throw StateError(
        'ServiceLocator not initialized. Call ServiceLocator.initialize() first.',
      );
    }

    final service = _services[T];
    if (service == null) {
      throw StateError('Service of type $T not found in ServiceLocator.');
    }

    return service as T;
  }

  /// Check if service locator is initialized
  static bool get isInitialized => _isInitialized;

  /// Reset service locator (mainly for testing)
  static void reset() {
    _services.clear();
    _isInitialized = false;
  }

  /// Convenience getters for commonly used services
  static AuthService get auth => get<AuthService>();
  static UserService get user => get<UserService>();
  static SchoolService get school => get<SchoolService>();
  // static DepartmentService get department => get<DepartmentService>(); // Bu servis henüz oluşturulmamış
  static CourseService get course => get<CourseService>();
  static MatchService get match => get<MatchService>();
  static GroupService get group => get<GroupService>();
  static NotificationService get notification => get<NotificationService>();
  static MessageService get message => get<MessageService>();
}
