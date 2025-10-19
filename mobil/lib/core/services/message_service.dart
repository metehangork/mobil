import 'api_client.dart';
import '../config/api_config.dart';

/// Message Service - REST API for message history and conversations
/// Note: Real-time messaging uses Socket.io (separate service)
class MessageService {
  final ApiClient _client;

  MessageService(this._client);

  /// Get all conversations
  Future<ApiResponse> getConversations({
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    return await _client.get(
      '${ApiConfig.messages}/conversations',
      queryParams: queryParams,
    );
  }

  /// Get specific conversation details
  Future<ApiResponse> getConversation(int conversationId) async {
    return await _client.get(
      '${ApiConfig.messages}/conversations/$conversationId',
    );
  }

  /// Get messages in a conversation
  Future<ApiResponse> getMessages(
    int conversationId, {
    int page = 1,
    int limit = 100,
    int? beforeMessageId, // For pagination: get messages before this ID
  }) async {
    final queryParams = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (beforeMessageId != null) {
      queryParams['before'] = beforeMessageId.toString();
    }

    return await _client.get(
      '${ApiConfig.messages}/conversations/$conversationId/messages',
      queryParams: queryParams,
    );
  }

  /// Send a message (via REST - for offline/fallback)
  /// Real-time messaging should use Socket.io
  Future<ApiResponse> sendMessage(
    int conversationId,
    String content, {
    String? type, // 'text', 'image', 'file'
    String? mediaUrl,
  }) async {
    final body = <String, dynamic>{
      'conversationId': conversationId,
      'content': content,
    };

    if (type != null) {
      body['type'] = type;
    }
    if (mediaUrl != null) {
      body['mediaUrl'] = mediaUrl;
    }

    return await _client.post(
      ApiConfig.messages,
      body: body,
    );
  }

  /// Mark messages as read
  Future<ApiResponse> markAsRead(int conversationId) async {
    return await _client.post(
      '${ApiConfig.messages}/conversations/$conversationId/read',
    );
  }

  /// Delete a message
  Future<ApiResponse> deleteMessage(int messageId) async {
    return await _client.delete('${ApiConfig.messages}/$messageId');
  }

  /// Search messages
  Future<ApiResponse> searchMessages(
    String query, {
    int? conversationId,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (conversationId != null) {
      queryParams['conversationId'] = conversationId.toString();
    }

    return await _client.get(
      '${ApiConfig.messages}/search',
      queryParams: queryParams,
    );
  }

  /// Create or get conversation with a user
  Future<ApiResponse> getOrCreateConversation(int userId) async {
    return await _client.post(
      '${ApiConfig.messages}/conversations',
      body: {'userId': userId},
    );
  }

  /// Get unread message count
  Future<ApiResponse> getUnreadCount() async {
    return await _client.get('${ApiConfig.messages}/unread/count');
  }
}
