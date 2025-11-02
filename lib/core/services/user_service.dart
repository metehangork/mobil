import 'api_client.dart';
import '../config/api_config.dart';

/// User Service
class UserService {
  final ApiClient _client;

  UserService(this._client);

  /// Get current user's full profile
  Future<ApiResponse> getMyProfile() async {
    return await _client.get('${ApiConfig.auth}/me');
  }

  /// Get another user's profile
  Future<ApiResponse> getUserProfile(int userId) async {
    return await _client.get('${ApiConfig.auth}/user/$userId');
  }

  /// Update basic user info
  Future<ApiResponse> updateProfile(Map<String, dynamic> data) async {
    return await _client.patch(
      '${ApiConfig.users}/me',
      body: data,
    );
  }

  /// Update extended profile (about, interests, hobbies, skills)
  Future<ApiResponse> updateExtendedProfile(Map<String, dynamic> data) async {
    return await _client.patch(
      '${ApiConfig.users}/me/profile',
      body: data,
    );
  }

  /// Update user settings (privacy, notifications)
  Future<ApiResponse> updateSettings(Map<String, dynamic> settings) async {
    return await _client.patch(
      '${ApiConfig.users}/me/settings',
      body: settings,
    );
  }

  /// Set user online
  Future<ApiResponse> setOnline() async {
    return await _client.post('${ApiConfig.users}/me/online');
  }

  /// Set user offline
  Future<ApiResponse> setOffline() async {
    return await _client.post('${ApiConfig.users}/me/offline');
  }

  /// Update FCM token for push notifications
  Future<ApiResponse> updateFcmToken(String fcmToken) async {
    return await _client.patch(
      '${ApiConfig.users}/me/fcm-token',
      body: {'fcmToken': fcmToken},
    );
  }
}
