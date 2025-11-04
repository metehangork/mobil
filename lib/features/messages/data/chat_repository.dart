import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../core/config/api_config.dart';
import '../data/chat_models.dart';

class ChatRepository {
  final Future<String?> Function() getToken;
  ChatRepository({required this.getToken});

  String get _base => ApiConfig.apiUrl;

  Future<List<ConversationSummary>> listConversations() async {
    final token = await getToken();
    if (token == null) throw Exception('Auth token missing');
    final uri = Uri.parse('$_base/chats');
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    });
    if (res.statusCode != 200) {
      debugPrint('Chats list failed: ${res.statusCode} ${res.body}');
      throw Exception('Konuşmalar alınamadı');
    }
    final data = json.decode(res.body) as List;
    return data.map((e) => ConversationSummary.fromJson(e)).toList();
  }

  Future<List<ChatMessage>> getMessages(int conversationId,
      {int limit = 50, DateTime? before}) async {
    final token = await getToken();
    if (token == null) throw Exception('Auth token missing');
    final qp = {
      'limit': '$limit',
      if (before != null) 'before': before.toIso8601String(),
    };
    final uri = Uri.parse('$_base/chats/$conversationId/messages')
        .replace(queryParameters: qp);
    final res =
        await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) throw Exception('Mesajlar alınamadı');
    final data = json.decode(res.body) as List;
    return data.map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<ChatMessage> sendMessage(int conversationId, String text,
      {String type = 'text'}) async {
    final token = await getToken();
    if (token == null) throw Exception('Auth token missing');
    final uri = Uri.parse('$_base/chats/$conversationId/messages');
    final res = await http.post(uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({'text': text, 'type': type}));
    if (res.statusCode != 201) throw Exception('Mesaj gönderilemedi');
    return ChatMessage.fromJson(json.decode(res.body));
  }

  Future<void> markRead(int conversationId, {DateTime? upTo}) async {
    final token = await getToken();
    if (token == null) throw Exception('Auth token missing');
    final uri = Uri.parse('$_base/chats/$conversationId/read');
    final res = await http.post(uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({if (upTo != null) 'upTo': upTo.toIso8601String()}));
    if (res.statusCode != 200) throw Exception('Okundu işaretlenemedi');
  }

  Future<int> ensureConversation(int otherUserId) async {
    final token = await getToken();
    if (token == null) throw Exception('Auth token missing');
    final uri = Uri.parse('$_base/chats/ensure');
    final res = await http.post(uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({'otherUserId': otherUserId}));
    if (res.statusCode != 200) throw Exception('Sohbet başlatılamadı');
    final data = json.decode(res.body);
    return (data['id'] as num).toInt();
  }

  /// Search for users by email, first name, or last name
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final token = await getToken();
    if (token == null) throw Exception('No auth token');

    final uri = Uri.parse('${ApiConfig.apiUrl}/auth/search')
        .replace(queryParameters: {'q': query});
    final res =
        await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    if (res.statusCode != 200) {
      throw Exception('Search failed: ${res.statusCode}');
    }

    final data = json.decode(res.body);
    return List<Map<String, dynamic>>.from(data['users'] ?? []);
  }

  /// Birden fazla kullanıcının online/offline durumunu sorgula (REST API fallback)
  /// 
  /// [userIds] - Sorgulanacak kullanıcı ID'leri
  /// Returns: Map<userId, 'online'|'offline'>
  Future<Map<String, String>> getUsersOnlineStatus(List<String> userIds) async {
    final token = await getToken();
    if (token == null) throw Exception('Token yok');
    
    if (userIds.isEmpty) return {};
    
    // Comma-separated string oluştur: "1,2,3,4"
    final idsParam = userIds.join(',');
    
    final res = await http.get(
      Uri.parse('${ApiConfig.apiUrl}/users/status?ids=$idsParam'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (res.statusCode != 200) {
      throw Exception('Status query failed: ${res.statusCode}');
    }
    
    final data = json.decode(res.body) as Map<String, dynamic>;
    
    // JSON'dan Map<String, String>'e dönüştür
    return data.map((key, value) => MapEntry(key, value.toString()));
  }
}
