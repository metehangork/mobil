import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../config/api_config.dart';

/// Authentication Service
class AuthService {
  final ApiClient _client;
  final SharedPreferences _prefs;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  AuthService(this._client, this._prefs);

  /// Request email verification code
  Future<ApiResponse> requestVerificationCode(String email) async {
    return await _client.post(
      '${ApiConfig.auth}/request-verification',
      body: {'email': email},
    );
  }

  /// Verify code and login
  Future<ApiResponse> verifyCode(String email, String code) async {
    final response = await _client.post(
      '${ApiConfig.auth}/verify-code',
      body: {
        'email': email,
        'code': code,
      },
    );

    if (response.isSuccess && response.data != null) {
      // Save token
      final token = response.data['token'];
      if (token != null) {
        await saveToken(token);
        _client.setToken(token);
      }
    }

    return response;
  }

  /// Get current user
  Future<ApiResponse> getCurrentUser() async {
    return await _client.get('${ApiConfig.auth}/me');
  }

  /// Search users
  Future<ApiResponse> searchUsers(String query) async {
    return await _client.get(
      '${ApiConfig.auth}/search',
      queryParams: {'q': query},
    );
  }

  /// Save token to storage
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _client.setToken(token);
  }

  /// Get saved token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      _client.setToken(token);
    }
    return token;
  }

  /// Remove token (logout)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _client.setToken(null);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout
  Future<void> logout() async {
    await removeToken();
  }
}
