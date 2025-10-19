import 'api_client.dart';
import '../config/api_config.dart';

/// Notification Service
class NotificationService {
  final ApiClient _client;

  NotificationService(this._client);

  /// Get all notifications with optional filters
  Future<ApiResponse> getNotifications({
    String? type, // 'match', 'message', 'group', 'system'
    bool? isRead,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }
    if (isRead != null) {
      queryParams['isRead'] = isRead.toString();
    }

    return await _client.get(
      ApiConfig.notifications,
      queryParams: queryParams,
    );
  }

  /// Get unread notifications count
  Future<ApiResponse> getUnreadCount() async {
    return await _client.get('${ApiConfig.notifications}/unread/count');
  }

  /// Mark notification as read
  Future<ApiResponse> markAsRead(int notificationId) async {
    return await _client.patch(
      '${ApiConfig.notifications}/$notificationId/read',
    );
  }

  /// Mark all notifications as read
  Future<ApiResponse> markAllAsRead() async {
    return await _client.post('${ApiConfig.notifications}/mark-all-read');
  }

  /// Delete a notification
  Future<ApiResponse> deleteNotification(int notificationId) async {
    return await _client.delete('${ApiConfig.notifications}/$notificationId');
  }

  /// Delete all read notifications
  Future<ApiResponse> deleteAllRead() async {
    return await _client.delete('${ApiConfig.notifications}/read');
  }

  /// Get only unread notifications
  Future<ApiResponse> getUnreadNotifications({
    String? type,
    int limit = 50,
  }) async {
    return getNotifications(
      type: type,
      isRead: false,
      limit: limit,
    );
  }
}
