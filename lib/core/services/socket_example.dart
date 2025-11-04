import 'package:flutter/material.dart';
import 'package:unicampus/core/services/socket_service.dart';

/// Socket.io ile mesajlaşma örneği
/// Bu dosyayı mesajlaşma ekranınızda referans olarak kullanabilirsiniz
class SocketExample extends StatefulWidget {
  final String currentUserId;
  final String chatUserId;

  const SocketExample({
    super.key,
    required this.currentUserId,
    required this.chatUserId,
  });

  @override
  State<SocketExample> createState() => _SocketExampleState();
}

class _SocketExampleState extends State<SocketExample> {
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeSocket();
    _listenToSocketEvents();
  }

  /// Socket.io bağlantısını başlat
  void _initializeSocket() {
    // Backend sunucu adresinizi buraya yazın
    const serverUrl = 'https://kafadarkampus.online';
    const token = 'your-jwt-token-here'; // JWT token gerekli

    _socketService.connect(serverUrl, token);

    // Konuşma geçmişini yükle (opsiyonel - artık kullanılmıyor)
    // _socketService.getConversation(
    //   userId1: widget.currentUserId,
    //   userId2: widget.chatUserId,
    // );
  }

  /// Socket olaylarını dinle
  void _listenToSocketEvents() {
    // Bağlantı durumu
    _socketService.connectionStream.listen((isConnected) {
      setState(() {
        _isConnected = isConnected;
      });
    });

    // Mesaj olayları
    _socketService.messageStream.listen((event) {
      final type = event['type'];
      final data = event['data'];

      switch (type) {
        case 'new_message':
          // Yeni mesaj geldi
          setState(() {
            _messages.insert(0, data);
          });

          // Mesajı okundu olarak işaretle (server'da id int olabilir veya string)
          final dynamic rawId = data['id'];
          int? messageId;
          if (rawId is int) {
            messageId = rawId;
          } else if (rawId is num) {
            messageId = rawId.toInt();
          } else if (rawId is String) {
            messageId = int.tryParse(rawId);
          }

          if (messageId != null) {
            _socketService.markMessageAsRead(messageId: messageId);
          } else {
            // Fallback: try parse created id or skip
            debugPrint(
                'Unable to parse message id for read receipt: ${data['id']}');
          }
          break;

        case 'message_sent':
          // Kendi mesajımız gönderildi
          setState(() {
            _messages.insert(0, data['message']);
          });
          break;

        case 'conversation_history':
          // Konuşma geçmişi geldi
          setState(() {
            _messages.clear();
            _messages.addAll(List<Map<String, dynamic>>.from(data['messages']));
          });
          break;

        case 'message_error':
          // Hata oluştu
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mesaj gönderilemedi: ${data['error']}')),
          );
          break;
      }
    });

    // Yazıyor bildirimi
    _socketService.typingStream.listen((data) {
      if (data['userId'] == widget.chatUserId) {
        setState(() {
          _isTyping = data['isTyping'] == true;
        });
      }
    });

    // Kullanıcı durum değişiklikleri
    _socketService.statusStream.listen((data) {
      // Çevrimiçi/çevrimdışı durumunu UI'de gösterebilirsiniz
      debugPrint('Durum değişti: $data');
    });
  }

  /// Mesaj gönder
  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    // SocketService yeni API: conversationId ve text gerekli
    _socketService.sendMessage(
      conversationId: 1, // Konuşma ID'si - dinamik olmalı
      text: text,
    );

    _messageController.clear();

    // Yazıyor bildirimini kapat
    _socketService.sendTyping(
      receiverId: widget.chatUserId,
      isTyping: false,
    );
  }

  /// Yazma durumu değişti
  void _onTypingChanged(String text) {
    if (text.isNotEmpty) {
      _socketService.sendTyping(
        receiverId: widget.chatUserId,
        isTyping: true,
      );
    } else {
      _socketService.sendTyping(
        receiverId: widget.chatUserId,
        isTyping: false,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    // Not: SocketService.dispose() sadece uygulama kapanırken çağrılmalı
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlaşma'),
        actions: [
          // Bağlantı durumu göstergesi
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(
              _isConnected ? Icons.circle : Icons.circle_outlined,
              color: _isConnected ? Colors.green : Colors.red,
              size: 12,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Yazıyor bildirimi
          if (_isTyping)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: const Text(
                'Yazıyor...',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),

          // Mesaj listesi
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMine = message['sender_id'] == widget.currentUserId;

                return Align(
                  alignment:
                      isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['content'] ?? '',
                          style: TextStyle(
                            color: isMine ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message['created_at'] ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            color: isMine ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Mesaj gönderme alanı
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity( 0.3),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _onTypingChanged,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
