import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/socket_service.dart';
import '../../data/chat_models.dart';
import '../../data/chat_repository.dart';

part 'messages_state.dart';

class MessagesCubit extends Cubit<MessagesState> {
  final ChatRepository repo;
  final SocketService _socketService = SocketService();
  StreamSubscription<Map<String, dynamic>>? _statusSubscription;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  MessagesCubit(this.repo) : super(const MessagesState.initial()) {
    _initializeSocketListeners();
  }

  /// Socket event listener'ları başlat
  void _initializeSocketListeners() {
    // Yeni mesaj geldiğinde listeyi güncelle
    _messageSubscription = _socketService.messageStream.listen((event) {
      final type = event['type'];
      
      if (type == 'new_message' || type == 'message_sent') {
        // Yeni mesaj geldi - listeyi refresh et
        print('📨 [MessagesCubit] Yeni mesaj, liste yenileniyor...');
        refresh();
      }
    });

    _statusSubscription = _socketService.statusStream.listen((data) {
      // Tek kullanıcı durumu değişti
      if (data['userId'] != null && data['status'] != null) {
        final userId = int.tryParse(data['userId'].toString());
        final isOnline = data['status'] == 'online';
        
        if (userId != null) {
          _updateUserOnlineStatus(userId, isOnline);
        }
      }
      
      // Bulk online status sorgusu yanıtı (Map<userId, status>)
      if (data['type'] == 'online_users' && data['data'] != null) {
        final Map<String, dynamic> statuses = data['data'] as Map<String, dynamic>;
        
        for (final entry in statuses.entries) {
          final userId = int.tryParse(entry.key);
          final isOnline = entry.value == 'online';
          
          if (userId != null) {
            _updateUserOnlineStatus(userId, isOnline);
          }
        }
      }
    });
  }

  /// Konuşma listesinde belirli bir kullanıcının online durumunu güncelle
  void _updateUserOnlineStatus(int userId, bool isOnline) {
    final updatedConversations = state.conversations.map((conv) {
      if (conv.otherUserId == userId) {
        return conv.copyWith(isOnline: isOnline);
      }
      return conv;
    }).toList();

    emit(state.copyWith(conversations: updatedConversations));
  }

  /// Konuşmaları yükle
  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await repo.listConversations();
      emit(state.copyWith(loading: false, conversations: items));
      
      // Yüklendikten sonra online durumlarını sorgula
      _fetchOnlineStatuses();
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  /// Tüm konuşmalardaki kullanıcıların online durumunu sorgula
  void _fetchOnlineStatuses() async {
    if (state.conversations.isEmpty) return;
    
    final userIds = state.conversations
        .map((conv) => conv.otherUserId.toString())
        .toList();
    
    if (userIds.isEmpty) return;

    // Önce Socket.io'yu dene (realtime)
    if (_socketService.isConnected) {
      print('🔍 [MessagesCubit] Socket ile online status sorgulanıyor: ${userIds.length} kullanıcı');
      _socketService.getOnlineStatus(userIds);
    } else {
      // Socket bağlı değilse REST API'yi kullan (fallback)
      print('⚠️ [MessagesCubit] Socket bağlı değil, REST API fallback kullanılıyor');
      try {
        final statuses = await repo.getUsersOnlineStatus(userIds);
        
        // Map<userId, status> formatında gelir
        for (final entry in statuses.entries) {
          final userId = int.tryParse(entry.key);
          final isOnline = entry.value == 'online';
          
          if (userId != null) {
            _updateUserOnlineStatus(userId, isOnline);
          }
        }
        
        print('✅ [MessagesCubit] REST API\'den ${statuses.length} kullanıcı durumu alındı');
      } catch (e) {
        print('❌ [MessagesCubit] REST API fallback hatası: $e');
      }
    }
  }

  /// Manuel yenileme (pull-to-refresh)
  Future<void> refresh() => load();

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    _messageSubscription?.cancel();
    return super.close();
  }
}
