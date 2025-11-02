import 'api_client.dart';
import '../config/api_config.dart';

class ProfileService {
  final ApiClient _client;

  ProfileService(this._client);

  /// Get user profile
  Future<ApiResponse> getProfile(String userId) async {
    return await _client.get('${ApiConfig.users}/$userId');
  }

  /// Update user profile
  Future<ApiResponse> updateProfile(Map<String, dynamic> profileData) async {
    return await _client.patch('${ApiConfig.users}/profile', body: profileData);
  }

  /// Upload profile picture
  Future<ApiResponse> uploadProfilePicture(String imagePath) async {
    // TODO: Implement file upload
    return ApiResponse.error(message: 'Not implemented', statusCode: 501);
  }

  /// Get user preferences
  Future<ApiResponse> getPreferences() async {
    return await _client.get('${ApiConfig.users}/preferences');
  }

  /// Update user preferences
  Future<ApiResponse> updatePreferences(
      Map<String, dynamic> preferences) async {
    return await _client.patch('${ApiConfig.users}/preferences',
        body: preferences);
  }

  /// Get user stats
  Future<ApiResponse> getStats() async {
    return await _client.get('${ApiConfig.users}/stats');
  }

  /// Update profile visibility
  Future<ApiResponse> updateVisibility(Map<String, dynamic> visibility) async {
    return await _client.patch('${ApiConfig.users}/visibility',
        body: visibility);
  }
}
