/// Navigation route constants for the app
class AppRoutes {
  // Auth routes
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyEmail = '/verify-email';
  
  // Main shell route
  static const String shell = '/shell';
  
  // Tab root routes (relative to shell)
  static const String home = 'home';
  static const String courses = 'courses';
  static const String groups = 'groups';
  static const String messages = 'messages';
  static const String profile = 'profile';
  static const String profileEdit = 'profile/edit';
  
  // Nested routes examples (to be expanded)
  static const String courseDetail = 'course-detail';
  static const String groupDetail = 'group-detail';
  static const String chatDetail = 'chat-detail';
}
