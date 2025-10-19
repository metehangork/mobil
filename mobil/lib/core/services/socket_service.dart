import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Socket.io ile anlık mesajlaşma servisi
/// Singleton pattern kullanılarak tek instance oluşturulur
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  // Stream controllers - UI'ye event göndermek için
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  // Getters
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  /// Socket.io bağlantısını başlat
  /// 
  /// [serverUrl] - Backend sunucu adresi (örn: 'http://192.168.1.5:3000')
  /// [userId] - Bağlanan kullanıcının ID'si
  void connect(String serverUrl, String userId) {
    if (_isConnected && _socket != null) {
      developer.log('Zaten bağlı, tekrar bağlanmaya gerek yok', name: 'SocketService');
      return;
    }

    developer.log('Socket.io bağlantısı başlatılıyor: $serverUrl', name: 'SocketService');

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Sadece websocket kullan
          .disableAutoConnect() // Otomatik bağlanma kapalı
          .enableReconnection() // Bağlantı kopunca yeniden dene
          .setReconnectionAttempts(5) // 5 deneme
          .setReconnectionDelay(2000) // 2 saniye bekle
          .build(),
    );

    // ==================== BAĞLANTI OLAYLARI ====================
    
    _socket!.onConnect((_) {
      _isConnected = true;
      _connectionController.add(true);
      developer.log('✅ Socket.io bağlandı', name: 'SocketService');
      
      // Kullanıcıyı çevrimiçi olarak işaretle
      _socket!.emit('user_online', {'userId': userId});
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _connectionController.add(false);
      developer.log('❌ Socket.io bağlantısı koptu', name: 'SocketService');
    });

    _socket!.onConnectError((data) {
      developer.log('❌ Bağlantı hatası: $data', name: 'SocketService');
    });

    _socket!.onError((data) {
      developer.log('❌ Socket hatası: $data', name: 'SocketService');
    });

    // ==================== MESAJLAŞMA OLAYLARI ====================

    // Yeni mesaj geldi
    _socket!.on('new_message', (data) {
      developer.log('📨 Yeni mesaj geldi: $data', name: 'SocketService');
      _messageController.add({
        'type': 'new_message',
        'data': data,
      });
    });

    // Mesaj gönderildi onayı
    _socket!.on('message_sent', (data) {
      developer.log('✅ Mesaj gönderildi: $data', name: 'SocketService');
      _messageController.add({
        'type': 'message_sent',
        'data': data,
      });
    });

    // Mesaj hatası
    _socket!.on('message_error', (data) {
      developer.log('❌ Mesaj hatası: $data', name: 'SocketService');
      _messageController.add({
        'type': 'message_error',
        'data': data,
      });
    });

    // Mesaj okundu
    _socket!.on('message_read_receipt', (data) {
      developer.log('👁️ Mesaj okundu: $data', name: 'SocketService');
      _messageController.add({
        'type': 'message_read',
        'data': data,
      });
    });

    // ==================== YAZIYOR BİLDİRİMİ ====================

    _socket!.on('user_typing', (data) {
      developer.log('✍️ Yazıyor bildirimi: $data', name: 'SocketService');
      _typingController.add(data);
    });

    // ==================== DURUM DEĞİŞİKLİĞİ ====================

    _socket!.on('status_change', (data) {
      developer.log('🔄 Durum değişti: $data', name: 'SocketService');
      _statusController.add(data);
    });

    // ==================== BAĞLANTI ONAY ====================

    _socket!.on('connected', (data) {
      developer.log('✅ Bağlantı onaylandı: $data', name: 'SocketService');
    });

    // Bağlantıyı başlat
    _socket!.connect();
  }

  /// Mesaj gönder
  /// 
  /// [senderId] - Gönderen kullanıcı ID
  /// [receiverId] - Alıcı kullanıcı ID
  /// [content] - Mesaj içeriği
  /// [conversationId] - Konuşma ID (opsiyonel)
  void sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? conversationId,
  }) {
    if (!_isConnected || _socket == null) {
      developer.log('❌ Socket bağlı değil, mesaj gönderilemedi', name: 'SocketService');
      return;
    }

    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      if (conversationId != null) 'conversationId': conversationId,
    };

    _socket!.emit('send_message', messageData);
    developer.log('📤 Mesaj gönderildi: $messageData', name: 'SocketService');
  }

  /// Yazıyor bildirimi gönder
  /// 
  /// [senderId] - Yazan kullanıcı ID
  /// [receiverId] - Alıcı kullanıcı ID
  /// [isTyping] - Yazıyor mu (true) / yazmayı bıraktı mı (false)
  void sendTyping({
    required String senderId,
    required String receiverId,
    required bool isTyping,
  }) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('typing', {
      'senderId': senderId,
      'receiverId': receiverId,
      'isTyping': isTyping,
    });

    developer.log('✍️ Yazıyor bildirimi: $isTyping', name: 'SocketService');
  }

  /// Mesajı okundu olarak işaretle
  /// 
  /// [messageId] - Mesaj ID
  /// [userId] - Okuyan kullanıcı ID
  void markMessageAsRead({
    required String messageId,
    required String userId,
  }) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('message_read', {
      'messageId': messageId,
      'userId': userId,
    });

    developer.log('👁️ Mesaj okundu işareti gönderildi: $messageId', name: 'SocketService');
  }

  /// Konuşma geçmişini al
  /// 
  /// [userId1] - İlk kullanıcı ID
  /// [userId2] - İkinci kullanıcı ID
  /// [limit] - Maksimum mesaj sayısı (varsayılan: 50)
  /// [offset] - Başlangıç noktası (pagination için)
  void getConversation({
    required String userId1,
    required String userId2,
    int limit = 50,
    int offset = 0,
  }) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('get_conversation', {
      'userId1': userId1,
      'userId2': userId2,
      'limit': limit,
      'offset': offset,
    });

    // Konuşma verisi geldiğinde messageStream'e düşecek
    _socket!.on('conversation_data', (data) {
      developer.log('📚 Konuşma geçmişi alındı: ${data['count']} mesaj', name: 'SocketService');
      _messageController.add({
        'type': 'conversation_history',
        'data': data,
      });
    });

    _socket!.on('conversation_error', (data) {
      developer.log('❌ Konuşma geçmişi hatası: $data', name: 'SocketService');
    });
  }

  /// Belirtilen kullanıcıların çevrimiçi durumunu kontrol et
  /// 
  /// [userIds] - Kontrol edilecek kullanıcı ID listesi
  void getOnlineStatus(List<String> userIds) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('get_online_users', {'userIds': userIds});

    _socket!.on('online_users_data', (data) {
      developer.log('👥 Çevrimiçi kullanıcılar: $data', name: 'SocketService');
      _statusController.add({
        'type': 'online_users',
        'data': data,
      });
    });
  }

  /// Manuel çıkış yap
  /// 
  /// [userId] - Çıkış yapan kullanıcı ID
  void logout(String userId) {
    if (_socket != null) {
      _socket!.emit('user_logout', {'userId': userId});
      disconnect();
    }
  }

  /// Bağlantıyı kapat
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _connectionController.add(false);
      developer.log('🔌 Socket.io bağlantısı kapatıldı', name: 'SocketService');
    }
  }

  /// Servisi temizle (uygulama kapanırken)
  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _statusController.close();
    _connectionController.close();
    developer.log('🗑️ SocketService temizlendi', name: 'SocketService');
  }
}
