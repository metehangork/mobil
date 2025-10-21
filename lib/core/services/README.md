# Flutter API Service Layer - Usage Guide

## 🚀 Setup

### 1. Initialize Services in main.dart

```dart
import 'package:flutter/material.dart';
import 'core/services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize all services
  await ServiceLocator.initialize();
  
  runApp(MyApp());
}
```

### 2. Configure API Base URL

Check `lib/core/config/api_config.dart` - currently set to:
- Base URL: `http://37.148.210.244:3000`
- All endpoints configured

## 📦 Available Services

### AuthService
```dart
final authService = ServiceLocator.auth;

// Request verification code
await authService.requestVerificationCode('user@email.com');

// Verify code and login
final response = await authService.verifyCode('user@email.com', '123456');
if (response.isSuccess) {
  // Token automatically saved and set in ApiClient
  print('Logged in!');
}

// Check if logged in
bool loggedIn = await authService.isLoggedIn();

// Logout
await authService.logout();
```

### UserService
```dart
final userService = ServiceLocator.user;

// Get my profile
final profile = await userService.getMyProfile();

// Update profile
await userService.updateProfile(
  fullName: 'New Name',
  phone: '+90123456789',
);

// Update extended profile
await userService.updateExtendedProfile(
  bio: 'Computer Science student',
  interests: ['AI', 'Web Dev', 'Mobile Dev'],
  studyHabits: ['Morning', 'Library'],
);

// Update settings
await userService.updateSettings(
  allowMatchRequests: true,
  showOnlineStatus: true,
);

// Set online/offline status
await userService.setOnline();
await userService.setOffline();
```

### SchoolService & DepartmentService
```dart
final schoolService = ServiceLocator.school;
final deptService = ServiceLocator.department;

// Search schools
final schools = await schoolService.getSchools(
  search: 'Istanbul',
  city: 'Istanbul',
  type: 'university',
);

// Get school details
final school = await schoolService.getSchool(1);

// Get school's departments
final departments = await schoolService.getSchoolDepartments(1);

// Get department's courses
final courses = await deptService.getDepartmentCourses(10, semester: 3);
```

### CourseService
```dart
final courseService = ServiceLocator.course;

// Search courses
final courses = await courseService.getCourses(
  search: 'Calculus',
  departmentId: 10,
  semester: 1,
);

// Enroll in course
await courseService.enrollCourse(42);

// Get my enrolled courses
final myCourses = await courseService.getMyCourses();

// Find study partners for course
final matches = await courseService.getCourseMatches(42);
```

### MatchService
```dart
final matchService = ServiceLocator.match;

// Find study partners
final matches = await matchService.findMatches(
  interests: ['AI', 'Mobile Dev'],
  preferredGender: 'any',
  minScore: 30,
  limit: 20,
);

// Get my matches
final myMatches = await matchService.getMyMatches(status: 'pending');

// Accept a match
await matchService.acceptMatch(123);

// Reject a match
await matchService.rejectMatch(456);
```

### GroupService
```dart
final groupService = ServiceLocator.group;

// Search groups
final groups = await groupService.getGroups(
  search: 'Calculus',
  courseId: 42,
  studyType: 'online',
);

// Create group
await groupService.createGroup(
  name: 'Calculus Study Group',
  description: 'Study for midterm',
  courseId: 42,
  studyType: 'hybrid',
  city: 'Istanbul',
  maxMembers: 10,
);

// Join group
await groupService.joinGroup(5);

// Get my groups
final myGroups = await groupService.getMyGroups();

// Get group members
final members = await groupService.getGroupMembers(5);
```

### NotificationService
```dart
final notificationService = ServiceLocator.notification;

// Get notifications
final notifications = await notificationService.getNotifications(
  type: 'match',
  isRead: false,
);

// Get unread count
final count = await notificationService.getUnreadCount();

// Mark as read
await notificationService.markAsRead(123);

// Mark all as read
await notificationService.markAllAsRead();

// Delete notification
await notificationService.deleteNotification(123);
```

### MessageService
```dart
final messageService = ServiceLocator.message;

// Get conversations
final conversations = await messageService.getConversations();

// Get messages in conversation
final messages = await messageService.getMessages(10, limit: 50);

// Send message (fallback - use Socket.io for real-time)
await messageService.sendMessage(10, 'Hello!');

// Mark as read
await messageService.markAsRead(10);

// Search messages
final results = await messageService.searchMessages('homework');

// Get unread count
final unread = await messageService.getUnreadCount();
```

## 🎯 BLoC Integration Example

### Example: Profile Screen with BLoC

```dart
// profile_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/services/service_locator.dart';
import '../../core/services/user_service.dart';
import '../../core/services/api_client.dart';

// Events
abstract class ProfileEvent {}

class LoadProfile extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final String fullName;
  final String? bio;
  
  UpdateProfile({required this.fullName, this.bio});
}

// States
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}
class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> profile;
  ProfileLoaded(this.profile);
}
class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

// BLoC
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserService _userService = ServiceLocator.user;

  ProfileBloc() : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    
    final response = await _userService.getMyProfile();
    
    if (response.isSuccess) {
      emit(ProfileLoaded(response.data!));
    } else {
      emit(ProfileError(response.error ?? 'Failed to load profile'));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    
    final response = await _userService.updateProfile(
      fullName: event.fullName,
    );
    
    if (response.isSuccess) {
      // Reload profile
      add(LoadProfile());
    } else {
      emit(ProfileError(response.error ?? 'Failed to update profile'));
    }
  }
}
```

```dart
// profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileBloc()..add(LoadProfile()),
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (state is ProfileError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          
          if (state is ProfileLoaded) {
            return _buildProfile(context, state.profile);
          }
          
          return Container();
        },
      ),
    );
  }

  Widget _buildProfile(BuildContext context, Map<String, dynamic> profile) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Column(
        children: [
          Text('Name: ${profile['full_name']}'),
          Text('Email: ${profile['email']}'),
          Text('School: ${profile['school_name'] ?? 'Not set'}'),
          // ... more profile fields
        ],
      ),
    );
  }
}
```

## 🔄 Response Handling

All service methods return `ApiResponse`:

```dart
class ApiResponse {
  final bool isSuccess;
  final dynamic data;
  final String? error;
  final int? statusCode;
}
```

Example handling:

```dart
final response = await userService.getMyProfile();

if (response.isSuccess) {
  // Success - response.data contains the data
  final profile = response.data;
  print('User: ${profile['full_name']}');
} else {
  // Error - response.error contains error message
  print('Error: ${response.error}');
  
  // Check specific status codes
  if (response.statusCode == 401) {
    // Unauthorized - redirect to login
  } else if (response.statusCode == 404) {
    // Not found
  }
}
```

## 🔐 Authentication Flow

```dart
// 1. Request verification code
await ServiceLocator.auth.requestVerificationCode('user@email.com');

// 2. User enters code from email

// 3. Verify code
final response = await ServiceLocator.auth.verifyCode('user@email.com', '123456');

if (response.isSuccess) {
  // 4. Token is automatically saved and set in ApiClient
  // 5. All subsequent API calls will include the token
  
  // Navigate to home screen
  Navigator.pushReplacementNamed(context, '/home');
} else {
  // Show error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(response.error ?? 'Login failed')),
  );
}
```

## 🛠️ Error Handling

All services automatically handle:
- Network errors (timeout, no connection)
- HTTP errors (400, 401, 404, 500, etc.)
- JSON parsing errors
- Token expiration (401 responses)

Example with try-catch:

```dart
try {
  final response = await ServiceLocator.course.enrollCourse(courseId);
  
  if (response.isSuccess) {
    print('Enrolled successfully!');
  } else {
    print('Enrollment failed: ${response.error}');
  }
} catch (e) {
  print('Unexpected error: $e');
}
```

## 📝 Notes

- All services use the same `ApiClient` instance (singleton pattern)
- Authentication token is automatically included in all requests
- Token is persisted using `SharedPreferences`
- Services are initialized once at app startup
- Use `ServiceLocator.get<T>()` or convenience getters like `ServiceLocator.auth`
