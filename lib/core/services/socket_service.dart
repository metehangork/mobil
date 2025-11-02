import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Socket.io ile anlık mesajlaşma servisi
/// Singleton pattern kullanılarak tek instance oluşturulur
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
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
  /// [token] - JWT authentication token (GÜVENLİK!)
  void connect(String serverUrl, String token) {
    // developer.log çalışmıyorsa print ile debug
    print('🔌 [SocketService] connect() çağrıldı - serverUrl: $serverUrl');
    print(
        '🔌 [SocketService] Durum - _isConnected: $_isConnected, _socket null mu: ${_socket == null}, socket.connected: ${_socket?.connected}');

    // Eğer socket aktifse ve gerçekten bağlıysa, tekrar bağlanmaya gerek yok
    if (_socket != null && _socket!.connected) {
      print('✅ [SocketService] Socket zaten aktif ve bağlı, return');
      developer.log('✅ Zaten bağlı ve aktif, tekrar bağlanmaya gerek yok',
          name: 'SocketService');
      return;
    }

    // _isConnected flag'i socket.connected ile senkronize et
    if (_socket != null && !_socket!.connected) {
      print('⚠️ [SocketService] Socket var ama bağlı değil, dispose ediliyor');
      _isConnected = false; // Flag'i güncelle
      _connectionController.add(false);
    }

    // Eğer eski bir socket varsa (bağlı olmasa bile), önce dispose et
    if (_socket != null) {
      print('⚠️ [SocketService] Eski socket dispose ediliyor');
      developer.log('⚠️ Eski socket dispose ediliyor', name: 'SocketService');
      _socket!.dispose();
      _socket = null;
    }

    print('🔌 [SocketService] Yeni socket oluşturuluyor...');
    developer.log('🔌 Socket.io bağlantısı başlatılıyor: $serverUrl',
        name: 'SocketService');

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket']) // Sadece websocket kullan
          .disableAutoConnect() // Otomatik bağlanma kapalı
          .enableReconnection() // Bağlantı kopunca yeniden dene
          .setReconnectionAttempts(999999) // Unlimited reconnection
          .setReconnectionDelay(100) // 100ms bekle (ÇOK HIZLI!)
          .setReconnectionDelayMax(2000) // Maksimum 2 saniye
          .setRandomizationFactor(0.2) // Az randomization
          .setTimeout(10000) // Connection timeout 10 saniye
          .setAuth({'token': token}) // 🔐 JWT TOKEN GÖNDERİMİ
          .build(),
    );

    // ==================== BAĞLANTI OLAYLARI ====================

    _socket!.onConnect((_) {
      _isConnected = true;
      _connectionController.add(true);
      print('✅ [SocketService] Socket.io BAĞLANDI! (JWT authenticated)');
      developer.log('✅ Socket.io bağlandı (JWT authenticated)',
          name: 'SocketService');

      // Artık user_online emit'e gerek yok - JWT ile otomatik!
      // Backend JWT'den userId alıp otomatik çevrimiçi yapıyor
    });

    _socket!.onDisconnect((reason) {
      _isConnected = false;
      _connectionController.add(false);
      print('❌ [SocketService] Socket.io BAĞLANTI KOPTU - Sebep: $reason');
      developer.log('❌ Socket.io bağlantısı koptu - Sebep: $reason',
          name: 'SocketService');
      // Otomatik reconnect başlayacak (enableReconnection sayesinde)
    });

    _socket!.on('reconnect_attempt', (attempt) {
      print('🔄 [SocketService] Yeniden bağlanma denemesi: $attempt');
      developer.log('🔄 Yeniden bağlanma denemesi: $attempt',
          name: 'SocketService');
    });

    _socket!.on('reconnect', (attemptNumber) {
      print('✅ [SocketService] Yeniden bağlandı! (Deneme: $attemptNumber)');
      developer.log('✅ Yeniden bağlandı! (Deneme: $attemptNumber)',
          name: 'SocketService');
      _isConnected = true;
      _connectionController.add(true);
    });

    _socket!.on('reconnect_failed', (_) {
      print('❌ [SocketService] Yeniden bağlanma başarısız!');
      developer.log('❌ Yeniden bağlanma başarısız!', name: 'SocketService');
    });

    _socket!.onConnectError((data) {
      print('❌ [SocketService] Bağlantı hatası: $data');
      developer.log('❌ Bağlantı hatası: $data', name: 'SocketService');
    });

    _socket!.onError((data) {
      print('❌ [SocketService] Socket hatası: $data');
      developer.log('❌ Socket hatası: $data', name: 'SocketService');
    });

    // ==================== MESAJLAŞMA OLAYLARI ====================

    // Yeni mesaj geldi
    _socket!.on('new_message', (data) {
      print('📨 [SocketService] Yeni mesaj geldi: $data');
      developer.log('📨 Yeni mesaj geldi: $data', name: 'SocketService');
      _messageController.add({
        'type': 'new_message',
        'data': data,
      });
    });

    // Mesaj gönderildi onayı
    _socket!.on('message_sent', (data) {
      print('✅ [SocketService] Mesaj gönderildi: $data');
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
  /// [conversationId] - Konuşma ID (ZORUNLU)
  /// [text] - Mesaj metni
  ///
  /// NOT: senderId JWT token'dan otomatik alınıyor (güvenlik!)
  void sendMessage({
    required int conversationId,
    required String text,
  }) {
    if (!_isConnected || _socket == null) {
      developer.log('❌ Socket bağlı değil, mesaj gönderilemedi',
          name: 'SocketService');
      return;
    }

    final messageData = {
      'conversationId': conversationId,
      'text': text,
    };

    _socket!.emit('send_message', messageData);
    developer.log('📤 Mesaj gönderildi: $messageData', name: 'SocketService');
  }

  /// Yazıyor bildirimi gönder
  ///
  /// [receiverId] - Alıcı kullanıcı ID
  /// [isTyping] - Yazıyor mu (true) / yazmayı bıraktı mı (false)
  ///
  /// NOT: senderId JWT token'dan otomatik alınıyor (güvenlik!)
  void sendTyping({
    required String receiverId,
    required bool isTyping,
  }) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('typing', {
      'receiverId': receiverId,
      'isTyping': isTyping,
    });

    developer.log('✍️ Yazıyor bildirimi: $isTyping', name: 'SocketService');
  }

  /// Mesajı okundu olarak işaretle
  ///
  /// [messageId] - Mesaj ID
  /// NOT: userId JWT token'dan otomatik alınıyor (güvenlik!)
  void markMessageAsRead({
    required int messageId,
  }) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('message_read', {
      'messageId': messageId,
    });

    developer.log('👁️ Mesaj okundu işareti gönderildi: $messageId',
        name: 'SocketService');
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
      developer.log('📚 Konuşma geçmişi alındı: ${data['count']} mesaj',
          name: 'SocketService');
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
  /// NOT: userId JWT token'dan otomatik alınıyor
  void logout() {
    if (_socket != null) {
      _socket!.emit('user_logout', {});
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
